extends Area2D

## Moves the player's respawn point forward as they clear a section of the
## level, instead of always sending them back to the level start.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_respawn_point"):
		body.set_respawn_point(global_position)
