extends CharacterBody2D

## Free-swimming aquatic mook: gentle figure-eight wander near its spawn
## point until the player gets close, then a fast direct dash-chase. No
## gravity, no floor concept - pure 2D movement, same "ignore terrain
## entirely" convention as bat.gd/crow.gd. Contact damage (not a bullet)
## via ContactHitbox, matching bat.gd's DiveHitbox pattern.

enum State { IDLE, CHASE }

@export var idle_speed: float = 20.0
@export var chase_speed: float = 110.0
@export var aggro_range: float = 70.0
@export var wander_radius: float = 30.0
@export var contact_damage: int = 1
@export var score_value: int = 100

# Gentle rotation wiggle (independent of the X-scale facing flip below)
# reads as a tail/fin sway -- rotation rather than a Y-scale pulse since a
# fish's motion is a side-to-side undulation, not a wing flap.
const FIN_WIGGLE_SPEED := 6.0
const FIN_WIGGLE_AMPLITUDE := 0.12

@onready var visual: Node2D = $Visual
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var contact_hitbox: Area2D = $ContactHitbox

var state := State.IDLE
var _spawn_pos := Vector2.ZERO
var _time := 0.0
var _player: Node2D = null


func _ready() -> void:
	_spawn_pos = global_position
	hurtbox.hurt.connect(health_component.damage)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	contact_hitbox.area_entered.connect(_on_contact_hit)
	_register_with_level()


func _physics_process(delta: float) -> void:
	_time += delta
	visual.rotation = sin(_time * FIN_WIGGLE_SPEED) * FIN_WIGGLE_AMPLITUDE
	var player := _get_player()
	if player and global_position.distance_to(player.global_position) <= aggro_range:
		state = State.CHASE
	else:
		state = State.IDLE

	match state:
		State.IDLE:
			_do_idle_swim(delta)
		State.CHASE:
			_do_chase(delta, player)


func _do_idle_swim(delta: float) -> void:
	var offset := Vector2(sin(_time * 1.3) * wander_radius, cos(_time * 0.9) * wander_radius * 0.5)
	var target := _spawn_pos + offset
	var to_target := target - global_position
	if to_target.length() > 2.0:
		var dir := to_target.normalized()
		global_position += dir * idle_speed * delta
		if dir.x != 0.0:
			visual.scale.x = 1 if dir.x > 0.0 else -1


func _do_chase(delta: float, player: Node2D) -> void:
	var dir := (player.global_position - global_position).normalized()
	global_position += dir * chase_speed * delta
	if dir.x != 0.0:
		visual.scale.x = 1 if dir.x > 0.0 else -1


func _on_contact_hit(area: Area2D) -> void:
	if area.has_method("damage"):
		area.damage(contact_damage)


func _on_health_changed(_current: int, _max_hp: int) -> void:
	AudioManager.play(AudioManager.SFX_HIT)
	FxSpawner.spawn_hit(get_tree(), global_position)
	_flash_hit()


func _flash_hit() -> void:
	visual.modulate = Color(3.0, 3.0, 3.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.15)


func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player


# Lets a checkpoint-triggered player respawn re-instantiate this enemy if
# it's dead and positioned past the checkpoint - see level_base.gd's
# register_enemy()/_on_player_respawned().
func _register_with_level() -> void:
	var level := get_tree().current_scene
	if level and level.has_method("register_enemy"):
		level.register_enemy(self)


func _on_died() -> void:
	AudioManager.play(AudioManager.SFX_EXPLOSION)
	FxSpawner.spawn_explosion(get_tree(), global_position)
	GameState.register_kill(score_value)
	queue_free()
