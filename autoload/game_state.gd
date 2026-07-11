extends Node

## Cross-scene glue: score/lives/combo/weapon state that HUD, player, and
## enemies all react to via signals instead of holding direct references to
## each other. Persists across scene changes (autoloads survive
## change_scene_to_file), which is why lives/score live here rather than on
## the player node itself.

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal combo_changed(multiplier: int)
signal weapon_changed(weapon_id: String, level: int)
signal game_over
signal game_won

const STARTING_LIVES := 3
const COMBO_WINDOW := 2.5
const COMBO_STEP_KILLS := 3 # every N kills within the window raises the multiplier by 1
const MAX_COMBO_MULTIPLIER := 5

var score := 0
var lives := STARTING_LIVES
var current_level_index := 0
## Cheat-code toggle (see autoload/cheat_manager.gd) - when true, lose_life()
## is a no-op, so the player can never die or run out of lives.
var infinite_lives := false

var _combo_kills := 0
var _combo_multiplier := 1
var _combo_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer = max(_combo_timer - delta, 0.0)
		if _combo_timer == 0.0:
			_reset_combo()


func register_kill(points: int) -> void:
	_combo_kills += 1
	_combo_timer = COMBO_WINDOW
	var new_multiplier: int = min(1 + _combo_kills / COMBO_STEP_KILLS, MAX_COMBO_MULTIPLIER)
	if new_multiplier != _combo_multiplier:
		_combo_multiplier = new_multiplier
		combo_changed.emit(_combo_multiplier)
	add_score(points * _combo_multiplier)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func lose_life() -> void:
	if infinite_lives:
		return
	lives = max(lives - 1, 0)
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()


func reset_run() -> void:
	score = 0
	lives = STARTING_LIVES
	current_level_index = 0
	_reset_combo()
	score_changed.emit(score)
	lives_changed.emit(lives)


func _reset_combo() -> void:
	_combo_kills = 0
	_combo_multiplier = 1
	_combo_timer = 0.0
	combo_changed.emit(_combo_multiplier)
