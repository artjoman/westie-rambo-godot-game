extends Control

## Reusable overlay following the same pattern as settings_menu.gd — instanced
## as a child from main_menu.gd, dismissed via its own Back button.

signal closed

@onready var list_vbox: VBoxContainer = $Panel/ScrollContainer/VBox
@onready var back_button: Button = $Panel/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate()


func _populate() -> void:
	for entry in AchievementManager.get_all():
		var unlocked: bool = entry["unlocked"]
		var row := HBoxContainer.new()

		var title_label := Label.new()
		title_label.add_theme_font_size_override("font_size", 10)
		title_label.custom_minimum_size = Vector2(110, 0)
		title_label.text = entry["title"] if unlocked else "??? (LOCKED)"
		title_label.modulate = Color(1, 1, 1) if unlocked else Color(0.5, 0.5, 0.5)
		row.add_child(title_label)

		var desc_label := Label.new()
		desc_label.add_theme_font_size_override("font_size", 8)
		desc_label.text = entry["description"] if unlocked else "Locked"
		desc_label.modulate = Color(0.8, 0.8, 0.8) if unlocked else Color(0.4, 0.4, 0.4)
		row.add_child(desc_label)

		list_vbox.add_child(row)


func _on_back_pressed() -> void:
	closed.emit()
	queue_free()
