extends Control

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
const ACHIEVEMENTS_SCREEN_SCENE := preload("res://scenes/ui/achievements_screen.tscn")

@onready var start_button: Button = $VBox/StartButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var achievements_button: Button = $VBox/AchievementsButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var high_score_label: Label = $VBox/HighScoreLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	high_score_label.text = "HIGH SCORE: %d" % SaveManager.high_score
	MusicManager.play_menu()


func _on_start_pressed() -> void:
	SceneManager.start_new_game()


func _on_settings_pressed() -> void:
	add_child(SETTINGS_MENU_SCENE.instantiate())


func _on_achievements_pressed() -> void:
	add_child(ACHIEVEMENTS_SCREEN_SCENE.instantiate())


func _on_quit_pressed() -> void:
	get_tree().quit()
