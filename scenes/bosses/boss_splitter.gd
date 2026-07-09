extends "res://scenes/bosses/boss_base.gd"

## Paces back and forth firing at the player; at 50% health it splits once,
## spawning two weaker adds (reusing soldier.tscn) — the "adds" boss archetype.

@export var move_speed: float = 25.0
@export var move_range: float = 60.0
@export var add_scene: PackedScene

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer

var _spawn_x := 0.0
var _direction := 1
var _has_split := false


func _on_ready_extra() -> void:
	_spawn_x = global_position.x
	fire_timer.timeout.connect(_on_fire_timer_timeout)


func _physics_process(delta: float) -> void:
	global_position.x += _direction * move_speed * delta
	# Only flip when moving further past the boundary in the current
	# direction — a plain abs(offset) >= move_range check stays true every
	# frame once past the edge, flip-flopping direction every tick and
	# netting to ~zero movement instead of cleanly reversing (same bug
	# found and fixed in soldier.gd's _do_patrol()).
	var offset := global_position.x - _spawn_x
	if (_direction > 0 and offset >= move_range) or (_direction < 0 and offset <= -move_range):
		_direction *= -1


func _update_phase(current: int, max_hp: int) -> void:
	if not _has_split and current <= max_hp / 2:
		_has_split = true
		_spawn_adds()


func _spawn_adds() -> void:
	if add_scene == null:
		return
	var player := _get_player()
	if player and player.has_method("shake_camera"):
		player.shake_camera(5.0)
	for i in 2:
		var add: Node2D = add_scene.instantiate()
		var offset_x := -20.0 if i == 0 else 20.0
		add.global_position = global_position + Vector2(offset_x, 0)
		get_parent().add_child.call_deferred(add)


func _on_fire_timer_timeout() -> void:
	_fire_at_player(muzzle, 170.0, 1)
