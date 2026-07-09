extends Control

@onready var score_label: Label = $VBox/ScoreLabel
@onready var retry_button: Button = $VBox/RetryButton
@onready var menu_button: Button = $VBox/MenuButton


func _ready() -> void:
	score_label.text = "SCORE: %d" % GameState.score
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	MusicManager.play_menu()


func _on_retry_pressed() -> void:
	SceneManager.start_new_game()


func _on_menu_pressed() -> void:
	SceneManager.go_to_main_menu()
