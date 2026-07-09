extends CharacterBody2D

## Flies a sinusoidal weave while patrolling, then dive-bombs straight down
## when the player passes underneath, before climbing back to hover height.
## Contact damage (not a bullet) is dealt via DiveHitbox, since nothing else
## in this project deals damage by touching the player rather than shooting.

enum State { HOVER, DIVE, RETURN }

@export var patrol_speed: float = 40.0
@export var patrol_distance: float = 60.0
@export var hover_amplitude: float = 12.0
@export var hover_freq: float = 2.5
@export var dive_trigger_range: float = 20.0
@export var dive_speed: float = 220.0
@export var dive_max_drop: float = 90.0
@export var return_speed: float = 90.0
@export var contact_damage: int = 1
@export var score_value: int = 180

@onready var visual: Node2D = $Visual
@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var dive_hitbox: Area2D = $DiveHitbox

var state := State.HOVER
var facing := 1
var _spawn_x := 0.0
var _base_y := 0.0
var _time := 0.0
var _dive_start_y := 0.0
var _dive_cooldown := 0.0
var _player: Node2D = null


func _ready() -> void:
	_spawn_x = global_position.x
	_base_y = global_position.y
	hurtbox.hurt.connect(health_component.damage)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	dive_hitbox.area_entered.connect(_on_dive_hit)
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
	match state:
		State.HOVER:
			_do_hover(delta)
		State.DIVE:
			_do_dive(delta)
		State.RETURN:
			_do_return(delta)


func _do_hover(delta: float) -> void:
	global_position.x += facing * patrol_speed * delta
	global_position.y = _base_y + hover_amplitude * sin(_time * hover_freq)

	# Same boundary-flip fix used by soldier.gd/boss_splitter.gd: only flip
	# when moving further past the edge in the current direction, or the
	# facing sign flip-flops every tick and nets to no movement at all.
	var offset := global_position.x - _spawn_x
	if (facing > 0 and offset >= patrol_distance) or (facing < 0 and offset <= -patrol_distance):
		facing *= -1
		visual.scale.x = facing

	_dive_cooldown = max(_dive_cooldown - delta, 0.0)
	if _dive_cooldown > 0.0:
		return

	var player := _get_player()
	if player == null:
		return
	var dx := absf(player.global_position.x - global_position.x)
	if dx <= dive_trigger_range and player.global_position.y > global_position.y:
		state = State.DIVE
		_dive_start_y = global_position.y


func _do_dive(delta: float) -> void:
	global_position.y += dive_speed * delta
	if global_position.y >= _dive_start_y + dive_max_drop:
		state = State.RETURN


func _do_return(delta: float) -> void:
	global_position.y -= return_speed * delta
	if global_position.y <= _base_y:
		global_position.y = _base_y
		state = State.HOVER
		_dive_cooldown = 1.5


func _on_dive_hit(area: Area2D) -> void:
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


func _on_died() -> void:
	AudioManager.play(AudioManager.SFX_EXPLOSION)
	FxSpawner.spawn_explosion(get_tree(), global_position)
	GameState.register_kill(score_value)
	queue_free()
