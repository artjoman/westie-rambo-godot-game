extends CanvasLayer

## Only instanced when DisplayServer.is_touchscreen_available() (see
## level_base.gd) — the virtual joystick (movement) plus TouchScreenButtons
## (jump/shoot/aim/perk) that let a phone actually play the game, since
## player.gd's input is otherwise keyboard/gamepad only.


func _ready() -> void:
	# So level_base.gd can hide/show this overlay while paused without
	# needing a hard reference to it.
	add_to_group("touch_controls")


func _exit_tree() -> void:
	# Defensive: if this overlay is torn down mid-touch (level unload),
	# TouchScreenButton already releases its own action automatically, but
	# the joystick's Input.action_press calls are not auto-released the same
	# way — without this, a finger still down during a scene change could
	# leave move_left/move_right stuck pressed for whatever loads next.
	for action in ["move_left", "move_right", "aim_up", "aim_down"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)
