extends Area2D

## Spans a full water pool (surface to floor). Slows movement like the
## generic SlowZone, and additionally toggles the player's in_water state
## (gentler sink gravity + swim-kick jump) — see player.gd's
## set_in_water/_apply_gravity/_handle_jump. A splash particle burst at the
## surface line on enter/exit is the visual cue that something changed,
## since the physics change alone is otherwise invisible.

const SPLASH_TINT := Color(0.6, 0.8, 1.0)

@export var speed_multiplier: float = 0.5

@onready var _surface_y: float = global_position.y - $CollisionShape2D.shape.size.y / 2.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_speed_multiplier"):
		body.set_speed_multiplier(speed_multiplier)
	if body.has_method("set_in_water"):
		body.set_in_water(true)
	_splash(body.global_position.x)


func _on_body_exited(body: Node) -> void:
	if body.has_method("set_speed_multiplier"):
		body.set_speed_multiplier(1.0)
	if body.has_method("set_in_water"):
		body.set_in_water(false)
	_splash(body.global_position.x)


func _splash(at_x: float) -> void:
	FxSpawner.spawn_hit(get_tree(), Vector2(at_x, _surface_y), SPLASH_TINT)
