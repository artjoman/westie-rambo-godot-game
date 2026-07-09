extends Area2D

@export var speed_multiplier: float = 0.5


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_speed_multiplier"):
		body.set_speed_multiplier(speed_multiplier)


func _on_body_exited(body: Node) -> void:
	if body.has_method("set_speed_multiplier"):
		body.set_speed_multiplier(1.0)
