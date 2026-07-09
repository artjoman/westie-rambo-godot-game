extends CharacterBody2D

## Emitted after respawn() moves the player back to its checkpoint, so a
## level can reset enemies positioned ahead of that checkpoint instead of
## leaving them permanently cleared from an earlier attempt.
signal respawned

const SPEED := 90.0
const ACCEL := 600.0
const JUMP_VELOCITY := -220.0
const JUMP_CUT_MULTIPLIER := 0.5
const GRAVITY := 700.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.1
const MUZZLE_DISTANCE := 5.0
const MAX_WEAPON_LEVEL := 3

# Water is a shallow, low-risk detour: slow "drowning" sink instead of normal
# gravity, and each jump press gives a swim-kick back toward the surface
# rather than the usual floor-jump (coyote/buffer don't apply underwater).
const WATER_GRAVITY := 120.0
const WATER_SWIM_VELOCITY := -160.0
# Caps fall speed carried into water so a long fall doesn't "hard splash"
# before the lighter gravity has a chance to feel slow.
const WATER_ENTRY_SPLASH_CAP := 80.0
const WATER_TINT := Color(0.55, 0.75, 1.0)

const LASER_PULSE_SPEED := 20.0
const LASER_WIDTH_BASE := 2.0
const LASER_WIDTH_AMPLITUDE := 0.8

# Only a "real" landing (fast enough fall) kicks up dust — a small hop
# shouldn't look like it hit the ground hard.
const LANDING_DUST_MIN_VELOCITY := 250.0

# 1-2 hit deaths per the genre; i-frames stop a single overlap from
# registering as multiple hits in the same fraction of a second.
const MAX_HEALTH := 2
const INVULN_TIME := 1.0

# Perks: pickups that grant a standing ability rather than a weapon tier.
const JETPACK_THRUST := -160.0
const JETPACK_ACCEL := 900.0
const JETPACK_MAX_FUEL := 1.2
const JETPACK_REFILL_RATE := 2.0
const FLASHBANG_RADIUS := 90.0
const FLASHBANG_DAMAGE := 5

# Preloaded so adding a weapon tier is a new .tres file, not new code —
# WEAPON_TIERS[id][level - 1] looks up the active WeaponData.
const WEAPON_TIERS := {
	"pistol": [preload("res://resources/weapons/weapon_pistol_lv1.tres")],
	"spread": [
		preload("res://resources/weapons/weapon_spread_lv1.tres"),
		preload("res://resources/weapons/weapon_spread_lv2.tres"),
		preload("res://resources/weapons/weapon_spread_lv3.tres"),
	],
	"machine_gun": [
		preload("res://resources/weapons/weapon_machine_gun_lv1.tres"),
		preload("res://resources/weapons/weapon_machine_gun_lv2.tres"),
		preload("res://resources/weapons/weapon_machine_gun_lv3.tres"),
	],
	"laser": [
		preload("res://resources/weapons/weapon_laser_lv1.tres"),
		preload("res://resources/weapons/weapon_laser_lv2.tres"),
		preload("res://resources/weapons/weapon_laser_lv3.tres"),
	],
}

enum State { IDLE, RUN, JUMP, FALL }

@onready var visual: Node2D = $Visual
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle: Marker2D = $Muzzle
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var laser_beam: Line2D = $LaserBeam
@onready var laser_audio: AudioStreamPlayer = $LaserAudioPlayer
@onready var camera: Camera2D = $Camera2D

const SHAKE_DECAY := 8.0

var shake_amount := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var fire_cooldown := 0.0
var beam_tick_timer := 0.0
var beam_pulse_time := 0.0
var facing := 1
var aim_direction := Vector2.RIGHT
var speed_multiplier := 1.0
var respawn_position := Vector2.ZERO
var invuln_timer := 0.0
var weapon_levels: Dictionary = {}
var current_weapon_id := "pistol"
var current_weapon: WeaponData
var in_water := false
var has_jetpack := false
var jetpack_fuel := 0.0
var has_shield := false
var flashbang_count := 0
var _bullet_pool: Node = null
var _was_on_floor := false


func _ready() -> void:
	_setup_placeholder_animations()
	respawn_position = global_position
	add_to_group("player")
	health_component.max_health = MAX_HEALTH
	health_component.reset()
	hurtbox.hurt.connect(_on_hurt)
	health_component.died.connect(_on_died)
	weapon_levels[current_weapon_id] = 1
	_update_current_weapon()
	laser_audio.stream = AudioManager.SFX_LASER


func _physics_process(delta: float) -> void:
	invuln_timer = max(invuln_timer - delta, 0.0)
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	_update_aim_direction()
	_update_muzzle_position()
	_handle_shooting(delta)
	_handle_perk_use()
	var was_falling_fast := velocity.y > LANDING_DUST_MIN_VELOCITY
	move_and_slide()
	_check_landing(was_falling_fast)
	_update_animation_state()
	_update_camera_shake(delta)


func _check_landing(was_falling_fast: bool) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and was_falling_fast:
		FxSpawner.spawn_dust(get_tree(), global_position)
		AudioManager.play(AudioManager.SFX_LAND)
	_was_on_floor = on_floor


func shake_camera(amount: float) -> void:
	shake_amount = max(shake_amount, amount)


func _update_camera_shake(delta: float) -> void:
	if shake_amount <= 0.0:
		camera.offset = Vector2.ZERO
		return
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amount
	shake_amount = max(shake_amount - SHAKE_DECAY * delta, 0.0)


func _update_timers(delta: float) -> void:
	coyote_timer = COYOTE_TIME if is_on_floor() else max(coyote_timer - delta, 0.0)
	jump_buffer_timer = JUMP_BUFFER_TIME if Input.is_action_just_pressed("jump") else max(jump_buffer_timer - delta, 0.0)


func _apply_gravity(delta: float) -> void:
	var thrusting := (
		has_jetpack and not is_on_floor() and not in_water
		and Input.is_action_pressed("jump") and jetpack_fuel > 0.0
	)
	if thrusting:
		velocity.y = move_toward(velocity.y, JETPACK_THRUST, JETPACK_ACCEL * delta)
		jetpack_fuel = max(jetpack_fuel - delta, 0.0)
	elif not is_on_floor():
		velocity.y += (WATER_GRAVITY if in_water else GRAVITY) * delta

	if is_on_floor() and has_jetpack:
		jetpack_fuel = min(jetpack_fuel + JETPACK_REFILL_RATE * delta, JETPACK_MAX_FUEL)


func _handle_jump() -> void:
	if in_water:
		if Input.is_action_just_pressed("jump"):
			velocity.y = WATER_SWIM_VELOCITY
		return

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		AudioManager.play(AudioManager.SFX_JUMP)


func _handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var speed := SPEED * speed_multiplier
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, ACCEL * delta)
		facing = 1 if direction > 0.0 else -1
		visual.scale.x = facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)


func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier


func set_in_water(value: bool) -> void:
	if value and not in_water:
		velocity.y = min(velocity.y, WATER_ENTRY_SPLASH_CAP)
		visual.modulate = WATER_TINT
	elif not value and in_water:
		visual.modulate = Color(1.0, 1.0, 1.0)
	in_water = value


func pickup_weapon(weapon_id: String) -> void:
	var current_level: int = weapon_levels.get(weapon_id, 0)
	var tier_count: int = WEAPON_TIERS[weapon_id].size()
	weapon_levels[weapon_id] = min(current_level + 1, min(tier_count, MAX_WEAPON_LEVEL))
	current_weapon_id = weapon_id
	_update_current_weapon()


func _update_current_weapon() -> void:
	var level: int = weapon_levels.get(current_weapon_id, 1)
	current_weapon = WEAPON_TIERS[current_weapon_id][level - 1]
	GameState.weapon_changed.emit(current_weapon_id, level)


func pickup_perk(perk_id: String) -> void:
	match perk_id:
		"jetpack":
			has_jetpack = true
			jetpack_fuel = JETPACK_MAX_FUEL
		"shield":
			has_shield = true
		"flashbang":
			flashbang_count += 1
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_callout(perk_id.to_upper() + "!", Color(0.6, 0.9, 1.0))


func _handle_perk_use() -> void:
	if flashbang_count > 0 and Input.is_action_just_pressed("use_perk"):
		_use_flashbang()


func _use_flashbang() -> void:
	flashbang_count -= 1
	AudioManager.play(AudioManager.SFX_FLASHBANG)
	FxSpawner.spawn_flashbang(get_tree(), global_position)
	shake_camera(4.0)

	var shape := CircleShape2D.new()
	shape.radius = FLASHBANG_RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 4 # enemies layer, same mask the laser beam uses
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var space_state := get_world_2d().direct_space_state
	for result in space_state.intersect_shape(query, 32):
		var collider = result.collider
		if collider.has_method("damage"):
			collider.damage(FLASHBANG_DAMAGE)


func respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	invuln_timer = INVULN_TIME
	health_component.reset()
	respawned.emit()


func set_respawn_point(new_position: Vector2) -> void:
	respawn_position = new_position


func _on_hurt(amount: int) -> void:
	if invuln_timer > 0.0:
		return
	if has_shield:
		has_shield = false
		invuln_timer = INVULN_TIME
		AudioManager.play(AudioManager.SFX_SHIELD_BREAK)
		FxSpawner.spawn_hit(get_tree(), global_position, Color(0.4, 0.7, 1.0))
		return
	invuln_timer = INVULN_TIME
	AudioManager.play(AudioManager.SFX_PLAYER_HURT)
	shake_camera(3.0)
	_flash_hit()
	health_component.damage(amount)


func _flash_hit() -> void:
	visual.modulate = Color(3.0, 3.0, 3.0)
	var base_color := WATER_TINT if in_water else Color(1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", base_color, 0.15)


func _on_died() -> void:
	GameState.lose_life()
	if GameState.lives > 0:
		respawn()
	# else: GameState already emitted game_over; Milestone 10's scene
	# management owns the transition, not the player itself.


func _update_aim_direction() -> void:
	# Contra-style aim: horizontal facing plus an up/down modifier.
	# Milestone 2 (shooting) reads this to position the muzzle and pick a bullet direction.
	var vertical := 0.0
	if Input.is_action_pressed("aim_up"):
		vertical = -1.0
	elif Input.is_action_pressed("aim_down"):
		vertical = 1.0

	if vertical != 0.0 and Input.get_axis("move_left", "move_right") == 0.0 and abs(velocity.x) < 1.0:
		aim_direction = Vector2(0.0, vertical)
	else:
		aim_direction = Vector2(facing, vertical).normalized()


func _update_muzzle_position() -> void:
	# Muzzle is a direct child of the player root (not Visual) so its position
	# reflects aim_direction directly, without being doubly flipped by Visual's
	# facing scale. Rotating it too (with a visible barrel sprite as its
	# child) is the only on-screen indicator of aim direction the player has
	# — without it, a correctly-resetting aim is indistinguishable from a
	# stuck one unless you're actively watching bullet trajectories.
	muzzle.position = aim_direction * MUZZLE_DISTANCE
	muzzle.rotation = aim_direction.angle()


func _handle_shooting(delta: float) -> void:
	fire_cooldown = max(fire_cooldown - delta, 0.0)
	var shooting := Input.is_action_pressed("shoot")

	if current_weapon.is_beam:
		laser_beam.visible = shooting
		if shooting:
			if not laser_audio.playing:
				laser_audio.play()
			_handle_beam(delta)
		elif laser_audio.playing:
			laser_audio.stop()
		return

	laser_beam.visible = false
	if laser_audio.playing:
		laser_audio.stop()
	if not shooting or fire_cooldown > 0.0:
		return

	var pool := _get_bullet_pool()
	if pool == null:
		return

	_fire_bullet_spread(pool)
	FxSpawner.spawn_muzzle_flash(get_tree(), muzzle.global_position, aim_direction)
	AudioManager.play(AudioManager.SFX_SHOOT_SPREAD if current_weapon.weapon_id == "spread" else AudioManager.SFX_SHOOT)
	fire_cooldown = 1.0 / current_weapon.fire_rate


func _fire_bullet_spread(pool: Node) -> void:
	var count: int = current_weapon.bullets_per_shot
	var spread_rad := deg_to_rad(current_weapon.spread_angle_degrees)
	var base_angle := aim_direction.angle()

	for i in count:
		var t := 0.0 if count == 1 else (float(i) / float(count - 1)) - 0.5
		var angle := base_angle + t * spread_rad
		var direction := Vector2.RIGHT.rotated(angle)
		pool.fire(muzzle.global_position, direction, current_weapon.bullet_speed, current_weapon.damage)


func _handle_beam(delta: float) -> void:
	beam_pulse_time += delta

	var space_state := get_world_2d().direct_space_state
	var end_point := muzzle.global_position + aim_direction * current_weapon.beam_range
	var query := PhysicsRayQueryParameters2D.create(muzzle.global_position, end_point)
	query.collision_mask = 4 # enemies layer; enemy solid bodies sit on layer 0, so this only ever hits a Hurtbox
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := space_state.intersect_ray(query)

	var beam_end := end_point
	if result:
		beam_end = result.position
		beam_tick_timer -= delta
		if beam_tick_timer <= 0.0:
			beam_tick_timer = current_weapon.beam_tick_interval
			if result.collider.has_method("damage"):
				result.collider.damage(current_weapon.damage)
			# Synced to the damage tick rather than every frame — a
			# continuous 60/sec particle burst would be excessive.
			FxSpawner.spawn_hit(get_tree(), beam_end, current_weapon.beam_color)
	else:
		beam_tick_timer = 0.0

	laser_beam.points = [muzzle.position, to_local(beam_end)]
	# A flat static-colored line reads as inert even while actively firing —
	# pulsing width/brightness is the cheapest way to sell it as an energy
	# beam rather than a drawn segment.
	var pulse := sin(beam_pulse_time * LASER_PULSE_SPEED)
	laser_beam.width = LASER_WIDTH_BASE + pulse * LASER_WIDTH_AMPLITUDE
	var brightness := 1.0 + pulse * 0.3
	laser_beam.default_color = current_weapon.beam_color
	laser_beam.modulate = Color(brightness, brightness, brightness, 1.0)


func _get_bullet_pool() -> Node:
	if _bullet_pool == null or not is_instance_valid(_bullet_pool):
		_bullet_pool = get_tree().get_first_node_in_group("bullet_pool")
	return _bullet_pool


func _update_animation_state() -> void:
	var state := State.IDLE
	if not is_on_floor():
		state = State.JUMP if velocity.y < 0.0 else State.FALL
	elif abs(velocity.x) > 1.0:
		state = State.RUN

	match state:
		State.IDLE:
			anim_player.play("idle")
		State.RUN:
			anim_player.play("run")
		State.JUMP:
			anim_player.play("jump")
		State.FALL:
			anim_player.play("fall")


# Placeholder procedural animations standing in for real sprite-sheet animations.
# Once art lands, this is replaced by an AnimationTree blending sprite animations
# with the aim_direction above (see Milestone 1 plan notes on 8-directional aim overlay).
func _setup_placeholder_animations() -> void:
	var library := AnimationLibrary.new()
	library.add_animation("idle", _build_bob_animation(0.35, 1.0))
	library.add_animation("run", _build_bob_animation(0.9, 0.28))
	library.add_animation("jump", _build_squash_animation(0.85, 1.15, 0.12))
	library.add_animation("fall", _build_squash_animation(1.1, 0.9, 0.12))
	anim_player.add_animation_library("", library)


func _build_bob_animation(amplitude: float, duration: float) -> Animation:
	var anim := Animation.new()
	anim.length = duration
	anim.loop_mode = Animation.LOOP_LINEAR
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("Visual:position:y"))
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, duration * 0.5, -amplitude)
	anim.track_insert_key(track, duration, 0.0)
	return anim


func _build_squash_animation(_scale_x: float, scale_y: float, duration: float) -> Animation:
	# Only animates the y scale; x scale is left alone since it's driven by
	# _handle_horizontal_movement's facing flip and the two must not fight over it.
	var anim := Animation.new()
	anim.length = duration
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("Visual:scale:y"))
	anim.track_insert_key(track, 0.0, scale_y)
	anim.track_insert_key(track, duration, 1.0)
	return anim
