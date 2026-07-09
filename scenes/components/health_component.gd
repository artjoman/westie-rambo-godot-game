extends Node

## Shared by the player and every enemy (composition, not inheritance —
## Godot has no multiple inheritance, so health lives in a child node instead).

signal died
signal health_changed(current: int, max: int)

@export var max_health: int = 1

var current_health: int


func _ready() -> void:
	current_health = max_health


func damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
