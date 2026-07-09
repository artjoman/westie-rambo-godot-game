extends "res://scenes/bosses/boss_base.gd"

## Phase 0 (>66% hp): single center shot. Phase 1 (33-66%): 3-way volley.
## Phase 2 (<33%): rapid 3-way volley. A stationary "wall" boss — simplest
## of the roster, reusing turret-style timed fire against multiple muzzles.

@onready var muzzle_top: Marker2D = $MuzzleTop
@onready var muzzle_mid: Marker2D = $MuzzleMid
@onready var muzzle_bottom: Marker2D = $MuzzleBottom
@onready var fire_timer: Timer = $FireTimer


func _on_ready_extra() -> void:
	fire_timer.timeout.connect(_on_fire_timer_timeout)


func _update_phase(current: int, max_hp: int) -> void:
	var pct := float(current) / float(max_hp)
	if pct <= 0.33:
		phase = 2
		fire_timer.wait_time = 0.5
	elif pct <= 0.66:
		phase = 1
		fire_timer.wait_time = 0.9
	else:
		phase = 0
		fire_timer.wait_time = 1.4


func _on_fire_timer_timeout() -> void:
	match phase:
		0:
			_fire_at_player(muzzle_mid, 150.0, 1)
		_:
			_fire_at_player(muzzle_top, 150.0, 1)
			_fire_at_player(muzzle_mid, 150.0, 1)
			_fire_at_player(muzzle_bottom, 150.0, 1)
