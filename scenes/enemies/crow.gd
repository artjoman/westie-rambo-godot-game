extends CharacterBody2D

## Flies a flat straight patrol (no vertical weave, unlike bat.gd) and
## periodically drops an unaimed projectile straight down - an ambient
## hazard rather than a player-tracking attack.

@export var patrol_speed: float = 45.0
@export var patrol_distance: float = 70.0
@export var poop_speed: float = 140.0
@export var poop_damage: int = 1
@export var score_value: int = 160

@onready var visual: Node2D = $Visual
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var fire_timer: Timer = $FireTimer

## A flat-gliding sprite with zero visual variation reads as a rigid
## cardboard cutout being dragged sideways rather than a bird in flight — a
## fast Y-scale pulse on Visual (independent of the X-scale facing flip
## below) sells a wing flap cheaply, without needing sprite-sheet frames.
const WING_FLAP_SPEED := 9.0
const WING_FLAP_AMPLITUDE := 0.18

var facing := 1
var _spawn_x := 0.0
var _poop_pool: Node = null
var _time := 0.0


func _ready() -> void:
	_spawn_x = global_position.x
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
	_time += delta
	visual.scale.y = 1.0 + sin(_time * WING_FLAP_SPEED) * WING_FLAP_AMPLITUDE

	global_position.x += facing * patrol_speed * delta
	# Same boundary-flip fix as soldier.gd/bat.gd.
	var offset := global_position.x - _spawn_x
	if (facing > 0 and offset >= patrol_distance) or (facing < 0 and offset <= -patrol_distance):
		facing *= -1
		visual.scale.x = facing


func _on_fire_timer_timeout() -> void:
	var pool := _get_poop_pool()
	if pool == null:
		return
	pool.fire(global_position, Vector2.DOWN, poop_speed, poop_damage)


func _get_poop_pool() -> Node:
	if _poop_pool == null or not is_instance_valid(_poop_pool):
		_poop_pool = get_tree().get_first_node_in_group("poop_bullet_pool")
	return _poop_pool


func _on_health_changed(_current: int, _max_hp: int) -> void:
	AudioManager.play(AudioManager.SFX_HIT)
	FxSpawner.spawn_hit(get_tree(), global_position)
	_flash_hit()


func _flash_hit() -> void:
	visual.modulate = Color(3.0, 3.0, 3.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.15)


func _on_died() -> void:
	AudioManager.play(AudioManager.SFX_EXPLOSION)
	FxSpawner.spawn_explosion(get_tree(), global_position)
	GameState.register_kill(score_value)
	queue_free()
