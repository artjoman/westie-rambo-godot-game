extends Control

@onready var start_button: Button = $VBox/StartButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var high_score_label: Label = $VBox/HighScoreLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	high_score_label.text = "HIGH SCORE: %d" % SaveManager.high_score
	MusicManager.play_menu()


func _on_start_pressed() -> void:
	SceneManager.start_new_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
