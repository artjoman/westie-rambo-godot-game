extends CharacterBody2D

const GRAVITY := 700.0

enum State { PATROL, ALERT, SHOOT }

@export var patrol_speed: float = 50.0
# Kept modest rather than wide: the tightest platform margin across the 4
# soldier placements in level_01/02/03 is ~50px from spawn to the platform
# edge (level_02's Soldier1) — a wider default previously walked a soldier
# right off its platform into the adjacent water pit.
@export var patrol_distance: float = 40.0
@export var aggro_range: float = 120.0
@export var shoot_range: float = 100.0
@export var bullet_speed: float = 160.0
@export var damage: int = 1
@export var muzzle_distance: float = 8.0
@export var score_value: int = 150

@onready var visual: Node2D = $Visual
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var state := State.PATROL
var facing := 1
var _spawn_x := 0.0
var _player: Node2D = null
var _bullet_pool: Node = null


func _ready() -> void:
	_spawn_x = global_position.x
	hurtbox.hurt.connect(health_component.damage)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	_setup_idle_animation()
	anim_player.play("idle")
	_register_with_level()


# Lets a checkpoint-triggered player respawn re-instantiate this enemy if
# it's dead and positioned past the checkpoint - see level_base.gd's
# register_enemy()/_on_player_respawned().
func _register_with_level() -> void:
	var level := get_tree().current_scene
	if level and level.has_method("register_enemy"):
		level.register_enemy(self)


# A soldier standing dead-rigid between slow patrol steps reads as "frozen"
# even while technically moving — this subtle bob is the same technique
# player.gd uses (_build_bob_animation) so enemies feel as alive as the
# player does, not just faster.
func _setup_idle_animation() -> void:
	var anim := Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_LINEAR
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("Visual:position:y"))
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, 0.3, -1.0)
	anim.track_insert_key(track, 0.6, 0.0)
	var library := AnimationLibrary.new()
	library.add_animation("idle", anim)
	anim_player.add_animation_library("", library)


func _on_health_changed(_current: int, _max_hp: int) -> void:
	AudioManager.play(AudioManager.SFX_HIT)
	FxSpawner.spawn_hit(get_tree(), global_position)
	_flash_hit()


func _flash_hit() -> void:
	visual.modulate = Color(3.0, 3.0, 3.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.15)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var player := _get_player()
	_update_state(player)

	match state:
		State.PATROL:
			_do_patrol()
		State.ALERT:
			velocity.x = 0.0
		State.SHOOT:
			velocity.x = 0.0
			_face_player(player)

	muzzle.position = Vector2(muzzle_distance * facing, -4.0)
	move_and_slide()


func _update_state(player: Node2D) -> void:
	if player == null:
		state = State.PATROL
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= shoot_range:
		state = State.SHOOT
	elif dist <= aggro_range:
		state = State.ALERT
	else:
		state = State.PATROL


func _do_patrol() -> void:
	velocity.x = facing * patrol_speed
	# Only flip when moving *further* past the boundary in the current
	# facing direction — checking plain abs(offset) >= patrol_distance
	# stays true every frame once past the edge, so facing (and velocity's
	# sign) flip-flops every single tick and the soldier nets to ~zero
	# movement, freezing in place instead of cleanly reversing.
	var offset := global_position.x - _spawn_x
	if (facing > 0 and offset >= patrol_distance) or (facing < 0 and offset <= -patrol_distance):
		facing *= -1
		visual.scale.x = facing


func _face_player(player: Node2D) -> void:
	facing = 1 if player.global_position.x > global_position.x else -1
	visual.scale.x = facing


func _on_fire_timer_timeout() -> void:
	if state != State.SHOOT:
		return
	var player := _get_player()
	if player == null:
		return
	var pool := _get_enemy_bullet_pool()
	if pool == null:
		return
	var direction := (player.global_position - muzzle.global_position).normalized()
	pool.fire(muzzle.global_position, direction, bullet_speed, damage)
	FxSpawner.spawn_muzzle_flash(get_tree(), muzzle.global_position, direction)


func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player


func _get_enemy_bullet_pool() -> Node:
	if _bullet_pool == null or not is_instance_valid(_bullet_pool):
		_bullet_pool = get_tree().get_first_node_in_group("enemy_bullet_pool")
	return _bullet_pool


func _on_died() -> void:
	AudioManager.play(AudioManager.SFX_EXPLOSION)
	FxSpawner.spawn_explosion(get_tree(), global_position)
	GameState.register_kill(score_value)
	queue_free()
