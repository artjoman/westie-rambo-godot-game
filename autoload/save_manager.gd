extends Node

## Minimal persistent save data via Godot's ConfigFile — just a high score
## for now. user:// is the sandboxed, OS-appropriate writable data path
## (distinct from res://, which ships read-only with the game).

const SAVE_PATH := "user://save_data.cfg"

var high_score := 0


func _ready() -> void:
	_load()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = cfg.get_value("progress", "high_score", 0)


func save_high_score(score: int) -> void:
	if score <= high_score:
		return
	high_score = score
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "high_score", high_score)
	cfg.save(SAVE_PATH)
