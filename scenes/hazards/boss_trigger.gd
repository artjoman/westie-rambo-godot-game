extends Area2D

## Announces the boss encounter (shows the HUD boss-health-bar) the first
## time the player crosses into the arena. Camera-lock/gate-closing is left
## for later polish — this covers the functional trigger the boss loop needs.

@export var boss_path: NodePath

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	_triggered = true
	var boss: Node = get_node_or_null(boss_path)
	if boss:
		boss.announce()
		MusicManager.play_boss()
	if body.has_method("shake_camera"):
		body.shake_camera(5.0)
