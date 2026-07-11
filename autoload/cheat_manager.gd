extends Node

## Hidden cheat codes, active globally regardless of which scene is loaded:
## - Konami code (Up Up Down Down Left Right Left Right B A) toggles infinite
##   lives. Uses raw arrow-key + letter keycodes rather than the game's own
##   InputMap actions, both to match the classic code exactly and because
##   this project's controls are WASD-based (arrows/B/A aren't bound to
##   anything else, so there's no ambiguity).
## - Ctrl+[1-5] warps directly to that level, for quick testing.

const KONAMI_SEQUENCE := [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A,
]

var _konami_progress := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	_check_konami(event)
	_check_level_select(event)


func _check_konami(event: InputEventKey) -> void:
	if event.keycode == KONAMI_SEQUENCE[_konami_progress]:
		_konami_progress += 1
		if _konami_progress >= KONAMI_SEQUENCE.size():
			_konami_progress = 0
			_toggle_infinite_lives()
	else:
		# Restart the match from scratch, unless this same key is also a
		# valid *first* key (so mashing UP repeatedly re-syncs instead of
		# just failing the whole sequence).
		_konami_progress = 1 if event.keycode == KONAMI_SEQUENCE[0] else 0


func _toggle_infinite_lives() -> void:
	GameState.infinite_lives = not GameState.infinite_lives
	var message := "INFINITE LIVES " + ("ON!" if GameState.infinite_lives else "OFF")
	print("[cheat] ", message)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_callout(message, Color(1, 0.85, 0.2))


func _check_level_select(event: InputEventKey) -> void:
	if not event.ctrl_pressed:
		return
	var level_index := -1
	match event.keycode:
		KEY_1: level_index = 0
		KEY_2: level_index = 1
		KEY_3: level_index = 2
		KEY_4: level_index = 3
		KEY_5: level_index = 4
	if level_index < 0 or level_index >= SceneManager.LEVELS.size():
		return
	print("[cheat] warping to level ", level_index + 1)
	get_tree().paused = false # matches pause_menu.gd's quit-to-menu fix: a scene
	# change while still paused would leave the new scene's nodes frozen.
	GameState.reset_run()
	SceneManager.load_level(level_index)
