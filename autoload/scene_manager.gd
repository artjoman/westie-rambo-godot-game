extends Node

## Owns level progression and screen transitions. Levels/menus call into
## this rather than hardcoding change_scene_to_file paths, so the level
## order lives in one place.

const LEVELS := [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn",
]

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const GAME_OVER := "res://scenes/ui/game_over.tscn"
const WIN_SCREEN := "res://scenes/ui/win_screen.tscn"


func _ready() -> void:
	GameState.game_over.connect(_on_game_over)


func start_new_game() -> void:
	GameState.reset_run()
	load_level(0)


func load_level(index: int) -> void:
	GameState.current_level_index = index
	get_tree().change_scene_to_file.call_deferred(LEVELS[index])


func advance_level() -> void:
	var next := GameState.current_level_index + 1
	if next < LEVELS.size():
		load_level(next)
	else:
		_show_win_screen()


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU)


func _on_game_over() -> void:
	SaveManager.save_high_score(GameState.score)
	get_tree().change_scene_to_file.call_deferred(GAME_OVER)


func _show_win_screen() -> void:
	SaveManager.save_high_score(GameState.score)
	get_tree().change_scene_to_file.call_deferred(WIN_SCREEN)
