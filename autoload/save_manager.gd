extends Node

## Minimal persistent save data via Godot's ConfigFile — just a high score
## for now. user:// is the sandboxed, OS-appropriate writable data path
## (distinct from res://, which ships read-only with the game).

const SAVE_PATH := "user://save_data.cfg"
const DEFAULT_MUSIC_VOLUME_DB := 0.0
const DEFAULT_SFX_VOLUME_DB := 0.0

var high_score := 0
var music_volume_db := DEFAULT_MUSIC_VOLUME_DB
var sfx_volume_db := DEFAULT_SFX_VOLUME_DB
var unlocked_achievements: Dictionary = {}

## Coalesces the disk write while a volume slider is being dragged (which
## fires save_volume() on every tick) into one write shortly after the last
## change, instead of hitting user:// on every frame of the drag.
var _write_timer: Timer


func _ready() -> void:
	_load()
	_apply_volume()
	_write_timer = Timer.new()
	_write_timer.one_shot = true
	_write_timer.wait_time = 0.3
	_write_timer.timeout.connect(_write)
	add_child(_write_timer)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = cfg.get_value("progress", "high_score", 0)
		music_volume_db = cfg.get_value("settings", "music_volume_db", DEFAULT_MUSIC_VOLUME_DB)
		sfx_volume_db = cfg.get_value("settings", "sfx_volume_db", DEFAULT_SFX_VOLUME_DB)
		var stored: Variant = cfg.get_value("achievements", "unlocked", {})
		unlocked_achievements = stored if stored is Dictionary else {}


func save_high_score(score: int) -> void:
	if score <= high_score:
		return
	high_score = score
	_write()


func save_volume(music_db: float, sfx_db: float) -> void:
	music_volume_db = music_db
	sfx_volume_db = sfx_db
	_apply_volume()
	_write_timer.start()


func is_achievement_unlocked(id: String) -> bool:
	return unlocked_achievements.get(id, false)


func save_achievement_unlocked(id: String) -> void:
	if unlocked_achievements.get(id, false):
		return
	unlocked_achievements[id] = true
	_write()


func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume_db)


func _write() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "high_score", high_score)
	cfg.set_value("settings", "music_volume_db", music_volume_db)
	cfg.set_value("settings", "sfx_volume_db", sfx_volume_db)
	cfg.set_value("achievements", "unlocked", unlocked_achievements)
	cfg.save(SAVE_PATH)
