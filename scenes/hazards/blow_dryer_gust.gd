extends Area2D

## Wall-mounted blow dryer that pulses a strong horizontal gust on a timer
## instead of blowing constantly -- timing a dash through the "off" phase
## (or fighting through an "on" phase if you're willing to fight the wind)
## is the actual obstacle, not a permanent wind wall nobody can read.
## Telegraphed by a shake tween on the dryer sprite during the "on" phase.

@export var push_force: float = 100.0
@export var gust_direction: float = -1.0 # -1 = push left, 1 = push right
@export var on_duration: float = 1.2
@export var off_duration: float = 1.0

@onready var timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite

var _active := false
var _bodies_inside: Array = []
var _shake_tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	_start_phase(false)


func _start_phase(active: bool) -> void:
	_active = active
	timer.start(on_duration if active else off_duration)
	_apply_to_bodies()
	_update_visual()


func _on_timer_timeout() -> void:
	_start_phase(not _active)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_wind_push"):
		_bodies_inside.append(body)
		_apply_to_bodies()


func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)
	if body.has_method("set_wind_push"):
		body.set_wind_push(0.0)


func _apply_to_bodies() -> void:
	var value := push_force * gust_direction if _active else 0.0
	for body in _bodies_inside:
		if is_instance_valid(body) and body.has_method("set_wind_push"):
			body.set_wind_push(value)


func _update_visual() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	if not _active:
		sprite.position = Vector2.ZERO
		sprite.modulate = Color(1, 1, 1)
		return
	sprite.modulate = Color(1.3, 1.3, 1.0)
	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_property(sprite, "position:x", 1.5, 0.04)
	_shake_tween.tween_property(sprite, "position:x", -1.5, 0.04)
