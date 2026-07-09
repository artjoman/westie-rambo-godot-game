extends CharacterBody2D

## Cruises back and forth at a fixed depth (flat patrol, same technique as
## crow.gd) until the player enters range, then charges directly at them -
## a stronger, tankier cousin of piranha.gd's chase behavior. Contact
## damage only, no gravity, no floor concept.

enum State { PATROL, CHARGE }

@export var patrol_speed: float = 35.0
@export var patrol_distance: float = 80.0
@export var charge_speed: float = 130.0
@export var aggro_range: float = 90.0
@export var contact_damage: int = 2
@export var score_value: int = 220

@onready var visual: Node2D = $Visual
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var contact_hitbox: Area2D = $ContactHitbox

var state := State.PATROL
var facing := 1
var _spawn_x := 0.0
var _base_y := 0.0
var _player: Node2D = null


func _ready() -> void:
	_spawn_x = global_position.x
	_base_y = global_position.y
	hurtbox.hurt.connect(health_component.damage)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	contact_hitbox.area_entered.connect(_on_contact_hit)
	_register_with_level()


func _physics_process(delta: float) -> void:
	var player := _get_player()
	if player and global_position.distance_to(player.global_position) <= aggro_range:
		state = State.CHARGE
	else:
		state = State.PATROL

	match state:
		State.PATROL:
			_do_patrol(delta)
		State.CHARGE:
			_do_charge(delta, player)


func _do_patrol(delta: float) -> void:
	global_position.x += facing * patrol_speed * delta
	# Same boundary-flip fix as soldier.gd/crow.gd/bat.gd.
	var offset := global_position.x - _spawn_x
	if (facing > 0 and offset >= patrol_distance) or (facing < 0 and offset <= -patrol_distance):
		facing *= -1
		visual.scale.x = facing
	# Drift back toward patrol depth after a charge pulled it off-line.
	global_position.y = move_toward(global_position.y, _base_y, 20.0 * delta)


func _do_charge(delta: float, player: Node2D) -> void:
	var dir := (player.global_position - global_position).normalized()
	global_position += dir * charge_speed * delta
	facing = 1 if dir.x > 0.0 else -1
	visual.scale.x = facing


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


func _register_with_level() -> void:
	var level := get_tree().current_scene
	if level and level.has_method("register_enemy"):
		level.register_enemy(self)


func _on_died() -> void:
	AudioManager.play(AudioManager.SFX_EXPLOSION)
	FxSpawner.spawn_explosion(get_tree(), global_position)
	GameState.register_kill(score_value)
	queue_free()
