extends Node

## Persistent headless regression suite -- run before every export/commit
## instead of writing a one-off scratch_*.gd/tscn script.
##
## Run with:
##   godot --headless --path . tests/regression_test.tscn
##
## Prints PASS/FAIL per check plus a final summary, and exits with code 0
## if everything passed or 1 if anything failed (so it can gate a build
## script). The level-select cheat check runs dead last and calls
## get_tree().quit() itself immediately after, because triggering
## SceneManager.load_level() schedules a deferred change_scene_to_file
## that would otherwise free this very script out from under itself on
## the next frame.

var _pass_count := 0
var _fail_count := 0


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_pass_count += 1
		print("[PASS] ", label)
	else:
		_fail_count += 1
		print("[FAIL] ", label, (" -- " + detail) if detail else "")


func _ready() -> void:
	print("=== Rambo Westie regression suite ===")
	_check_scene_boot()
	await _check_music()
	await _check_touch_controls()
	await _check_cheat_konami()
	_check_save_manager()
	await _check_cheat_level_select() # must stay last -- see header comment
	_print_summary()
	# Not self.get_tree(): the level-select check above triggers a real
	# deferred change_scene_to_file, which can free this very node (it's
	# the tree's current_scene) before we get back here -- the main loop
	# singleton stays valid regardless, so quit through that instead.
	(Engine.get_main_loop() as SceneTree).quit(0 if _fail_count == 0 else 1)


func _check_scene_boot() -> void:
	print("--- scene boot ---")
	for path in [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/levels/level_01.tscn",
		"res://scenes/levels/level_02.tscn",
		"res://scenes/levels/level_03.tscn",
		"res://scenes/levels/level_04.tscn",
		"res://scenes/levels/level_05.tscn",
	]:
		var packed: PackedScene = load(path)
		var ok := packed != null
		var inst: Node = null
		if ok:
			inst = packed.instantiate()
			ok = inst != null
		_check("boot: " + path, ok)
		if inst:
			inst.free()


func _check_music() -> void:
	print("--- music generation/playback ---")
	MusicManager.play_menu()
	await get_tree().create_timer(0.2).timeout
	var player: AudioStreamPlayer = MusicManager._players[MusicManager._active_index]
	var stream: AudioStreamWAV = player.stream
	_check("menu track generated", stream != null)
	if stream:
		# Guards against the real-device SIGSEGV this project hit: a
		# generated loop must have real backing data *past* loop_end for
		# the resampler's interpolation lookahead, i.e. data must hold
		# more samples than loop_end accounts for.
		var total_samples: int = stream.data.size() / 2
		_check("menu track has loop-guard padding past loop_end",
			total_samples > stream.loop_end,
			"total_samples=%d loop_end=%d" % [total_samples, stream.loop_end])
	_check("menu track playing", player.playing)

	MusicManager.play_level()
	await get_tree().create_timer(1.2).timeout
	_check("crossfade to level track playing",
		MusicManager._players[MusicManager._active_index].playing)

	MusicManager.play_boss()
	await get_tree().create_timer(1.2).timeout
	_check("crossfade to boss track playing",
		MusicManager._players[MusicManager._active_index].playing)


func _check_touch_controls() -> void:
	print("--- touch controls ---")
	var packed: PackedScene = load("res://scenes/ui/touch_controls.tscn")
	var inst := packed.instantiate()
	add_child(inst)
	await get_tree().process_frame

	# Guards against the expand_mode regression where TextureRect icons
	# ballooned to their (2x-supersampled) native texture size instead of
	# the intended button box.
	var size_checks := [
		["JoystickBase/JoystickRing", Vector2(80, 80)],
		["JoystickBase/JoystickKnob", Vector2(28, 28)],
		["ShootVisual", Vector2(44, 44)],
		["JumpVisual", Vector2(40, 40)],
		["AimUpVisual", Vector2(32, 32)],
		["AimDownVisual", Vector2(32, 32)],
		["PerkVisual", Vector2(32, 32)],
		["PauseVisual", Vector2(24, 24)],
	]
	for c in size_checks:
		var node: Control = inst.get_node(c[0])
		var expected: Vector2 = c[1]
		_check("touch control size: " + c[0], node.size.is_equal_approx(expected),
			"actual=%s expected=%s" % [node.size, expected])

	# Guards against the joystick-vertical-axis regression (aim_up/aim_down
	# unreachable from the joystick, only from the standalone buttons).
	var joy: Control = inst.get_node("JoystickBase")
	var center: Vector2 = joy.size / 2.0

	var dir_checks := [
		["center (neutral)", Vector2(0, 0), false, false, false, false],
		["full right", Vector2(32, 0), false, true, false, false],
		["full left", Vector2(-32, 0), true, false, false, false],
		["full up (aim up)", Vector2(0, -32), false, false, true, false],
		["full down (aim down)", Vector2(0, 32), false, false, false, true],
		["diagonal up-right (45deg)", Vector2(24, -24), false, true, true, false],
		["diagonal down-left (45deg)", Vector2(-24, 24), true, false, false, true],
	]
	for c in dir_checks:
		joy._update_from_position(center + c[1])
		var ok: bool = (
			Input.is_action_pressed("move_left") == c[2]
			and Input.is_action_pressed("move_right") == c[3]
			and Input.is_action_pressed("aim_up") == c[4]
			and Input.is_action_pressed("aim_down") == c[5]
		)
		_check("joystick: " + c[0], ok)
	joy._reset()

	inst.queue_free()
	await get_tree().process_frame


func _check_cheat_konami() -> void:
	print("--- cheat: konami code (infinite lives) ---")
	GameState.infinite_lives = false

	var sequence: Array[Key] = [
		KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN,
		KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
		KEY_B, KEY_A,
	]
	for k in sequence:
		var evt := InputEventKey.new()
		evt.keycode = k
		evt.pressed = true
		Input.parse_input_event(evt)
		# parse_input_event() only queues the event -- _unhandled_input
		# doesn't fire until the next frame's input dispatch, so each key
		# needs its own frame boundary or the whole sequence gets flushed
		# out of order later (observed: toggles fired during an unrelated
		# later check instead of here).
		await get_tree().process_frame
	_check("konami code toggles infinite_lives on", GameState.infinite_lives)

	var lives_before := GameState.lives
	GameState.lose_life()
	_check("lose_life() is a no-op with infinite_lives on", GameState.lives == lives_before)

	for k in sequence:
		var evt := InputEventKey.new()
		evt.keycode = k
		evt.pressed = true
		Input.parse_input_event(evt)
		await get_tree().process_frame
	_check("konami code toggles infinite_lives back off", not GameState.infinite_lives)

	GameState.infinite_lives = false
	var wrong_sequence: Array[Key] = [
		KEY_UP, KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN,
		KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A,
	]
	for k in wrong_sequence:
		var evt := InputEventKey.new()
		evt.keycode = k
		evt.pressed = true
		Input.parse_input_event(evt)
		await get_tree().process_frame
	_check("wrong sequence does not trigger", not GameState.infinite_lives)


func _check_save_manager() -> void:
	print("--- save manager ---")
	var music_before := SaveManager.music_volume_db
	SaveManager.save_volume(-4.0, -3.0)
	_check("save_volume applies immediately",
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) == -4.0)
	SaveManager.save_volume(music_before, SaveManager.sfx_volume_db)


func _check_cheat_level_select() -> void:
	print("--- cheat: ctrl+level select ---")
	var level: Node = load("res://scenes/levels/level_01.tscn").instantiate()
	get_tree().root.add_child(level)

	var evt := InputEventKey.new()
	evt.keycode = KEY_3
	evt.ctrl_pressed = true
	evt.pressed = true
	Input.parse_input_event(evt)
	# Exactly one frame: enough for _unhandled_input to dispatch the queued
	# event, but no more -- SceneManager.load_level() sets
	# GameState.current_level_index synchronously before its deferred
	# change_scene_to_file call, and that deferred call would free this
	# very script (part of the current scene tree) if given a further
	# frame to run. Caller must not await anything after this returns.
	await get_tree().process_frame
	_check("ctrl+3 warps current_level_index to 2", GameState.current_level_index == 2,
		"actual=%d" % GameState.current_level_index)


func _print_summary() -> void:
	print("=== summary: ", _pass_count, " passed, ", _fail_count, " failed ===")
