extends Control

## Reusable settings overlay — instanced identically from main_menu.gd (before
## a run starts) and pause_menu.gd (mid-level, while get_tree().paused). No
## process_mode override needed: it inherits PROCESS_MODE_ALWAYS when parented
## under the (always-on) pause menu, and behaves normally under the main menu.

signal closed

@onready var music_slider: HSlider = $Panel/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/SfxRow/SfxSlider
@onready var back_button: Button = $Panel/BackButton


func _ready() -> void:
	music_slider.value = SaveManager.music_volume_db
	sfx_slider.value = SaveManager.sfx_volume_db
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	back_button.pressed.connect(_on_back_pressed)


func _on_music_changed(value: float) -> void:
	SaveManager.save_volume(value, sfx_slider.value)


func _on_sfx_changed(value: float) -> void:
	SaveManager.save_volume(music_slider.value, value)


func _on_back_pressed() -> void:
	closed.emit()
	queue_free()
