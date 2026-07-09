extends Control

@onready var score_label: Label = $VBox/ScoreLabel
@onready var high_score_label: Label = $VBox/HighScoreLabel
@onready var play_again_button: Button = $VBox/PlayAgainButton
@onready var menu_button: Button = $VBox/MenuButton


func _ready() -> void:
	score_label.text = "SCORE: %d" % GameState.score
	high_score_label.text = "HIGH SCORE: %d" % SaveManager.high_score
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	MusicManager.play_menu()


func _on_play_again_pressed() -> void:
	SceneManager.start_new_game()


func _on_menu_pressed() -> void:
	SceneManager.go_to_main_menu()
