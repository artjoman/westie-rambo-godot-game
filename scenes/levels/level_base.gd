extends Node2D

## Shared level plumbing: builds the terrain visual, clamps the player's
## camera to the level bounds, and turns a boss death into a level-complete
## signal. Individual levels override _build_terrain() with their own
## spans/enemy layout; this exists so level_02/level_03 don't re-duplicate
## the camera/boss wiring test_level.gd doesn't need (it's a dev sandbox,
## not a shipped level, so it's left as its own simpler script).

signal level_completed

const KILL_FLOOR_Y := 600.0
const TOUCH_CONTROLS_SCENE := preload("res://scenes/ui/touch_controls.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")

@export var camera_limit_left: float = 0.0
@export var camera_limit_right: float = 1280.0
@export var camera_limit_top: float = -2000.0
@export var camera_limit_bottom: float = 300.0

## Which way progress runs, for deciding which enemies are "past" a
## checkpoint on respawn. Vector2.RIGHT for the horizontal levels;
## a vertical climb level sets this to Vector2.UP instead.
@export var progress_direction: Vector2 = Vector2.RIGHT

@onready var terrain_visual: Node2D = $TerrainVisual

var _player: Node = null
var _pause_menu: CanvasLayer = null
var _died_this_level := false
var _level_elapsed_sec := 0.0
# Enemies self-register here on _ready() (see register_enemy()) so a
# checkpoint-triggered respawn can re-instantiate whichever ones are dead —
# queue_free() destroys the node, so this is the only surviving record of
# where it was and what it was.
var _enemy_records: Array[Dictionary] = []


func _ready() -> void:
	# Needed so _unhandled_input's pause toggle keeps firing once
	# get_tree().paused is true — this is the level's scene root with no
	# always-on ancestor otherwise. Gameplay nodes (player, enemies, etc.)
	# are unaffected: they stay default PROCESS_MODE_INHERIT and freeze
	# correctly, since only this node's own logic opts into ALWAYS.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_terrain()
	_setup_camera()
	_connect_boss()
	_connect_player()
	_setup_touch_controls()
	MusicManager.play_level()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _physics_process(delta: float) -> void:
	# process_mode = ALWAYS above means this now also runs while paused;
	# the kill-floor check below has no business running mid-pause.
	if get_tree().paused:
		return
	# Manual delta-sum rather than a wall-clock timestamp: sitting in the
	# pause menu must not count toward a speedrun achievement's clock, and
	# this line only ever runs on unpaused ticks thanks to the guard above.
	_level_elapsed_sec += delta
	# Catch-all so falling anywhere off the bottom of the level (an
	# unmapped gap, a missed jump into open space, etc.) always respawns
	# the player instead of an infinite silent fall — independent of
	# whatever specific hazard triggers do or don't cover that spot.
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player and _player.global_position.y > KILL_FLOOR_Y:
		_player.respawn()


func _toggle_pause() -> void:
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_close_pause_menu()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	get_tree().paused = true
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	_pause_menu.resumed.connect(_close_pause_menu)
	add_child(_pause_menu)
	_set_touch_controls_visible(false)


func _close_pause_menu() -> void:
	get_tree().paused = false
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
	_pause_menu = null
	_set_touch_controls_visible(true)


func _set_touch_controls_visible(is_visible: bool) -> void:
	var touch := get_tree().get_first_node_in_group("touch_controls")
	if touch:
		touch.visible = is_visible


func _build_terrain() -> void:
	pass # overridden by subclasses


func _setup_camera() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	camera.limit_top = camera_limit_top
	camera.limit_bottom = camera_limit_bottom


func _connect_boss() -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss:
		boss.defeated.connect(_on_boss_defeated)


func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_player = player
	player.respawned.connect(_on_player_respawned)


## On-screen joystick + action buttons for touch devices, since player.gd's
## input is otherwise keyboard/gamepad only. No-op on desktop/headless.
func _setup_touch_controls() -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	add_child(TOUCH_CONTROLS_SCENE.instantiate())


## Enemies call this from their own _ready() so a later checkpoint respawn
## can tell which ones are dead (queue_free()'d, so is_instance_valid()
## goes false) and re-instantiate the ones positioned past the checkpoint.
func register_enemy(enemy: Node) -> void:
	_enemy_records.append({
		"node": enemy,
		"scene_path": enemy.scene_file_path,
		"position": enemy.global_position,
	})


func _on_player_respawned() -> void:
	_died_this_level = true
	var checkpoint: Vector2 = _player.respawn_position
	# Collect first, mutate after: revived enemies self-register a brand new
	# record in their own _ready() (same as any other enemy), so the dead
	# record being replaced here must be dropped rather than reused - two
	# records pointing at one lineage would each try to revive it
	# independently on every future respawn, duplicating enemies forever.
	var to_revive: Array[Dictionary] = []
	for record in _enemy_records:
		# Untyped on purpose: once the original enemy is queue_free()'d, this
		# Variant holds a freed-object reference, and assigning that to a
		# statically-typed Node var throws "invalid previously freed
		# instance" even though is_instance_valid() on it is exactly how
		# we're meant to detect that case.
		var node = record["node"]
		if is_instance_valid(node):
			continue # still alive, leave it
		var origin: Vector2 = record["position"]
		if (origin - checkpoint).dot(progress_direction) <= 0.0:
			continue # cleared before the checkpoint, stays cleared
		if String(record["scene_path"]).is_empty():
			continue
		to_revive.append(record)

	for record in to_revive:
		_enemy_records.erase(record)
		var scene: PackedScene = load(record["scene_path"])
		var revived: Node2D = scene.instantiate()
		revived.global_position = record["position"]
		add_child.call_deferred(revived)


func _on_boss_defeated() -> void:
	AchievementManager.report_level_cleared(GameState.current_level_index, _level_elapsed_sec, _died_this_level)
	level_completed.emit()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_callout("SUPER!!", Color(1, 0.35, 0.1))
		hud.show_message("LEVEL COMPLETE!")
	await get_tree().create_timer(2.0).timeout
	SceneManager.advance_level()
