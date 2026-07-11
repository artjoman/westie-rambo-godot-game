extends Control

## Custom analog joystick: computes a drag vector and drives the existing
## move_left/move_right/aim_up/aim_down InputMap actions via Input.action_press/
## action_release, so player.gd's Input.get_axis("move_left","move_right") and
## Input.is_action_pressed("aim_up"/"aim_down") keep working unchanged
## regardless of input source (key, joypad, or this). The vertical component
## drives aim_up/aim_down exactly like the standalone AimUpButton/AimDownButton
## do, so combining it with horizontal drag reaches every 8-way direction
## player.gd's _update_aim_direction() already knows how to build (see
## player.gd's facing + vertical combination) -- the standalone aim buttons
## remain too, as an alternative input source for the same actions.

const MAX_RADIUS := 32.0
const DEADZONE := 0.15

@onready var knob: Control = $JoystickKnob

var _touch_index := -1
var _base_center := Vector2.ZERO
var _current_strength := 0.0 # signed, -1..1 (horizontal)
var _current_vertical := 0 # -1 = aim_up, 0 = neutral, 1 = aim_down


func _ready() -> void:
	_base_center = size / 2.0
	knob.position = _base_center - knob.size / 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_from_position(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_from_position(event.position)


func _update_from_position(local_pos: Vector2) -> void:
	var offset := local_pos - _base_center
	var clamped := offset.limit_length(MAX_RADIUS)
	knob.position = _base_center + clamped - knob.size / 2.0

	var strength := clamped.x / MAX_RADIUS
	if absf(strength) < DEADZONE:
		strength = 0.0
	_set_strength(strength)

	var vertical_ratio := clamped.y / MAX_RADIUS
	var vertical := 0
	if vertical_ratio < -DEADZONE:
		vertical = -1
	elif vertical_ratio > DEADZONE:
		vertical = 1
	_set_vertical(vertical)


func _reset() -> void:
	knob.position = _base_center - knob.size / 2.0
	_set_strength(0.0)
	_set_vertical(0)


func _set_strength(strength: float) -> void:
	if is_equal_approx(strength, _current_strength):
		return
	# Release whichever side was active before switching, so a fast
	# left<->right flick never leaves the old direction stuck held.
	if _current_strength < 0.0:
		Input.action_release("move_left")
	elif _current_strength > 0.0:
		Input.action_release("move_right")

	if strength < 0.0:
		Input.action_press("move_left", -strength)
	elif strength > 0.0:
		Input.action_press("move_right", strength)

	_current_strength = strength


func _set_vertical(vertical: int) -> void:
	if vertical == _current_vertical:
		return
	if _current_vertical < 0:
		Input.action_release("aim_up")
	elif _current_vertical > 0:
		Input.action_release("aim_down")

	if vertical < 0:
		Input.action_press("aim_up")
	elif vertical > 0:
		Input.action_press("aim_down")

	_current_vertical = vertical
