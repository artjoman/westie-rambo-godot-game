extends StaticBody2D

@export var fire_range: float = 140.0
@export var bullet_speed: float = 160.0
@export var damage: int = 1
@export var score_value: int = 100

@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer
@onready var visual: CanvasItem = $Visual

# Turret intentionally never relocates (it's a fixed gun emplacement), but a
# perfectly rigid sprite reads as a dead/frozen object rather than an active
# threat — a slow scanning wobble sells "on and watching" without moving it.
const IDLE_ROTATION_SPEED := 2.0
const IDLE_ROTATION_AMPLITUDE := 0.15

var _player: Node2D = null
var _bullet_pool: Node = null
var _idle_time := 0.0


func _ready() -> void:
	hurtbox.hurt.connect(health_component.damage)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	_register_with_level()


# Lets a checkpoint-triggered player respawn re-instantiate this enemy if
# it's dead and positioned past the checkpoint - see level_base.gd's
# register_enemy()/_on_player_respawned().
func _register_with_level() -> void:
	var level := get_tree().current_scene
	if level and level.has_method("register_enemy"):
		level.register_enemy(self)


func _physics_process(delta: float) -> void:
	_idle_time += delta
	visual.rotation = sin(_idle_time * IDLE_ROTATION_SPEED) * IDLE_ROTATION_AMPLITUDE


func _on_health_changed(_current: int, _max_hp: int) -> void:
	AudioManager.play(AudioManager.SFX_HIT)
	FxSpawner.spawn_hit(get_tree(), global_position)
	_flash_hit()


func _flash_hit() -> void:
	visual.modulate = Color(3.0, 3.0, 3.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.15)


func _on_fire_timer_timeout() -> void:
	var player := _get_player()
	if player == null:
		return
	var to_player := player.global_position - global_position
	if to_player.length() > fire_range:
		return

	var pool := _get_enemy_bullet_pool()
	if pool == null:
		return
	pool.fire(muzzle.global_position, to_player.normalized(), bullet_speed, damage)
	FxSpawner.spawn_muzzle_flash(get_tree(), muzzle.global_position, to_player.normalized())


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
