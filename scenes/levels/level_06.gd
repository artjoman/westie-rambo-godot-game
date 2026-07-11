extends "res://scenes/levels/level_base.gd"

## Vet clinic: a Chip 'n Dale-style capture encounter mid-level -- the vet
## worker NPC (background-only, unshootable, uninteractable) grabs the
## player, pinning them in place (player.set_captured(true) disables
## horizontal movement but leaves jump/aim/shoot untouched) while multiple
## enemy waves close in with nowhere to run. Also features drug-trap
## hazards that briefly reverse controls, ending in a caricature vet boss
## who throws syringes.

const GROUND_TOP_Y := 234.0
const LEVEL_WIDTH := 1450

@onready var capture_trigger: Area2D = $CaptureTrigger
@onready var vet_worker: Node2D = $VetWorker
## Ordered wave spawners: wave N+1 only starts once wave N is fully cleared
## (spawned and killed), so this reads as a real escalating multi-wave
## defense rather than one big simultaneous dogpile.
@onready var capture_wave_spawners: Array = [$CaptureSpawner1, $CaptureSpawner2, $CaptureSpawner3]

var _capture_active := false
var _current_wave_index := -1
var _wave_total_this_wave := 0
var _wave_spawned_this_wave := 0
var _wave_remaining := 0


func _build_terrain() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": LEVEL_WIDTH, "type": "ground", "top_y": GROUND_TOP_Y},
	]
	terrain_visual.build(spans)


func _ready() -> void:
	super._ready()
	capture_trigger.triggered.connect(_on_capture_triggered)
	for spawner in capture_wave_spawners:
		spawner.spawned.connect(_on_wave_enemy_spawned)


func _on_capture_triggered() -> void:
	if _capture_active:
		return
	_capture_active = true

	if _player:
		_player.set_captured(true)
		if _player.has_method("shake_camera"):
			_player.shake_camera(5.0)
	vet_worker.play_lunge()

	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_callout("CAUGHT!", Color(1.0, 0.3, 0.5))

	_current_wave_index = -1
	_start_next_wave()


func _start_next_wave() -> void:
	_current_wave_index += 1
	if _current_wave_index >= capture_wave_spawners.size():
		_end_capture()
		return

	var spawner = capture_wave_spawners[_current_wave_index]
	_wave_total_this_wave = spawner.wave.count
	_wave_spawned_this_wave = 0
	_wave_remaining = _wave_total_this_wave

	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_callout("WAVE %d!" % (_current_wave_index + 1), Color(1.0, 0.6, 0.15))

	spawner.start()


func _on_wave_enemy_spawned(enemy: Node2D) -> void:
	_wave_spawned_this_wave += 1
	enemy.tree_exited.connect(_on_wave_enemy_cleared)


func _on_wave_enemy_cleared() -> void:
	_wave_remaining -= 1
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if not _capture_active:
		return
	# A spawned enemy's tree_exited can fire during whole-tree teardown
	# (e.g. the player dies mid-encounter and the scene changes to
	# game-over while wave enemies are still alive) -- by the time that
	# reaches here, this level node itself may already be out of the tree,
	# and get_tree() on it returns null. Nothing left to release at that
	# point anyway.
	if not is_inside_tree():
		return
	# Both conditions matter: spawned catching up to total guards against
	# advancing mid-wave, in the gap between one enemy dying and the
	# spawner's timer producing the next.
	if _wave_remaining <= 0 and _wave_spawned_this_wave >= _wave_total_this_wave:
		_start_next_wave()


func _end_capture() -> void:
	_capture_active = false
	if _player:
		_player.set_captured(false)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_callout("FREE!", Color(0.4, 1.0, 0.5))
