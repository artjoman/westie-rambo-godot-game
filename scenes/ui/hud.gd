extends CanvasLayer

@onready var lives_label: Label = $TopLeft/VBox/LivesLabel
@onready var health_label: Label = $TopLeft/VBox/HealthLabel
@onready var weapon_label: Label = $TopLeft/VBox/WeaponLabel
@onready var combo_label: Label = $TopLeft/VBox/ComboLabel
@onready var score_label: Label = $TopRight/ScoreLabel
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var message_label: Label = $MessageLabel
@onready var callout_label: Label = $CalloutLabel
@onready var jetpack_label: Label = $TopLeft/VBox/JetpackLabel
@onready var shield_label: Label = $TopLeft/VBox/ShieldLabel
@onready var flashbang_label: Label = $TopLeft/VBox/FlashbangLabel

const COMBO_COLOR := Color(1, 0.85, 0.2)
const SUPER_COLOR := Color(1, 0.35, 0.1)
const PICKUP_COLOR := Color(0.3, 0.9, 1.0)
const ACHIEVEMENT_COLOR := Color(1.0, 0.84, 0.0)

var _player: Node = null
var _last_combo_multiplier := 1
var _callout_tween: Tween = null


func _ready() -> void:
	add_to_group("hud")
	GameState.score_changed.connect(_on_score_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.weapon_changed.connect(_on_weapon_changed)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	_on_score_changed(GameState.score)
	_on_lives_changed(GameState.lives)
	_on_combo_changed(1)
	boss_health_bar.visible = false

	_connect_player()


func _connect_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	_player.health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(_player.health_component.current_health, _player.health_component.max_health)
	_sync_weapon_label(_player.current_weapon_id, _player.weapon_levels.get(_player.current_weapon_id, 1))


func _process(_delta: float) -> void:
	# Perk state (fuel draining, shield consumed, flashbang count) changes
	# continuously/silently outside any signal, so it's cheaper to just poll
	# the player each frame than to wire a dedicated signal per perk.
	if _player == null or not is_instance_valid(_player):
		return
	jetpack_label.visible = _player.has_jetpack
	if _player.has_jetpack:
		var pct := int(round(_player.jetpack_fuel / _player.JETPACK_MAX_FUEL * 100.0))
		jetpack_label.text = "JETPACK: %d%%" % pct
	shield_label.visible = _player.has_shield
	flashbang_label.visible = _player.flashbang_count > 0
	if _player.flashbang_count > 0:
		flashbang_label.text = "FLASHBANG x%d" % _player.flashbang_count


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %d" % new_score


func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "LIVES: %d" % new_lives


func _on_health_changed(current: int, max_health: int) -> void:
	health_label.text = "HP: %d/%d" % [current, max_health]


func _on_combo_changed(multiplier: int) -> void:
	combo_label.text = "COMBO x%d" % multiplier
	combo_label.visible = multiplier > 1
	if multiplier > _last_combo_multiplier:
		if multiplier >= GameState.MAX_COMBO_MULTIPLIER:
			show_callout("SUPER COMBO!!", SUPER_COLOR)
			if _player and _player.has_method("shake_camera"):
				_player.shake_camera(4.0)
		else:
			show_callout("COMBO x%d!" % multiplier, COMBO_COLOR)
	_last_combo_multiplier = multiplier


func _on_weapon_changed(weapon_id: String, level: int) -> void:
	_sync_weapon_label(weapon_id, level)
	show_callout("NICE!", PICKUP_COLOR)


func _sync_weapon_label(weapon_id: String, level: int) -> void:
	weapon_label.text = "WEAPON: %s Lv%d" % [weapon_id.capitalize(), level]


func _on_achievement_unlocked(id: String) -> void:
	show_callout("ACHIEVEMENT: " + AchievementManager.get_title(id), ACHIEVEMENT_COLOR)


func show_boss_health(current: int, max_health: int) -> void:
	boss_health_bar.visible = true
	boss_health_bar.max_value = max_health
	boss_health_bar.value = current


func update_boss_health(current: int) -> void:
	boss_health_bar.value = current


func hide_boss_health() -> void:
	boss_health_bar.visible = false


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true


func hide_message() -> void:
	message_label.visible = false


func show_callout(text: String, color: Color = Color(1, 1, 1)) -> void:
	# Killing any in-flight tween before restarting is the same fix as
	# MusicManager's crossfade: without it, a stale fade-out tween from the
	# previous callout can finish mid-way through a new one and yank its
	# alpha/scale back down partway through the new popup.
	if _callout_tween and _callout_tween.is_valid():
		_callout_tween.kill()
	callout_label.text = text
	callout_label.modulate = color
	callout_label.scale = Vector2.ZERO
	callout_label.visible = true
	AudioManager.play(AudioManager.SFX_CALLOUT)
	_callout_tween = create_tween()
	_callout_tween.tween_property(callout_label, "scale", Vector2(1.2, 1.2), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_callout_tween.tween_property(callout_label, "scale", Vector2(1.0, 1.0), 0.08)
	_callout_tween.tween_interval(0.5)
	_callout_tween.tween_property(callout_label, "modulate:a", 0.0, 0.4)
	_callout_tween.tween_callback(func() -> void: callout_label.visible = false)
