extends CanvasLayer

## Instanced/freed by level_base.gd's pause toggle. process_mode is set to
## ALWAYS directly in the .tscn so this stays interactive while
## get_tree().paused freezes everything else.

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")

signal resumed

@onready var resume_button: Button = $VBox/ResumeButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton


func _ready() -> void:
	add_to_group("pause_menu")
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_resume_pressed() -> void:
	resumed.emit()


func _on_settings_pressed() -> void:
	add_child(SETTINGS_MENU_SCENE.instantiate())


func _on_quit_pressed() -> void:
	# Must unpause before the scene change — otherwise the freshly loaded
	# main menu's default PROCESS_MODE_INHERIT buttons would never process
	# input, since the tree would still be paused.
	get_tree().paused = false
	SceneManager.go_to_main_menu()
