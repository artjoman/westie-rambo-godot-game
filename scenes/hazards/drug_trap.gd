extends Area2D

## Drug puddle/spilled-pills hazard: disorients whoever steps in it. Unlike
## slow_zone.gd (effect only lasts while standing in the zone), dizziness
## has its own minimum duration here so a quick brush-through still fully
## disorients instead of clearing the instant the player leaves the zone.
## Re-entering while already dizzy just restarts the countdown.

@export var dizzy_duration: float = 3.0

@onready var timer: Timer = $Timer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)


func _on_body_entered(body: Node) -> void:
	if not body.has_method("set_dizzy"):
		return
	body.set_dizzy(true)
	timer.start(dizzy_duration)


func _on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_dizzy"):
		player.set_dizzy(false)
