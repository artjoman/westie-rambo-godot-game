extends Area2D

## Fires once, the first time the player crosses into this zone -- same
## fire-once shape as boss_trigger.gd, but this doesn't announce a boss: the
## level (see level_06.gd) listens for `triggered` and starts its own
## capture/wave-defense sequence (pin the player in place, play the vet
## worker's lunge, arm the wave spawners).

signal triggered

var _fired := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _fired or not body.is_in_group("player"):
		return
	_fired = true
	triggered.emit()
