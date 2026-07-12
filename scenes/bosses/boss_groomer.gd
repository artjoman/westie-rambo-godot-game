extends "res://scenes/bosses/boss_base.gd"

## Caricature groomer: blasts a fan of air-puffs from her blow dryer,
## widening from a single shot to a 5-way spread as phases drop -- a
## genuinely different attack shape from boss_vet's escalating repeated
## single-shot volley, not just a reskin of the same pattern. Reuses
## boss_base's shared plumbing; the spread math itself isn't in boss_base
## (no other boss needs it), so it lives here, mirroring how player.gd's
## own _fire_bullet_spread() builds an angular fan.

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer


func _on_ready_extra() -> void:
	fire_timer.timeout.connect(_on_fire_timer_timeout)


func _update_phase(current: int, max_hp: int) -> void:
	var pct := float(current) / float(max_hp)
	if pct <= 0.33:
		phase = 2
		fire_timer.wait_time = 0.8
	elif pct <= 0.66:
		phase = 1
		fire_timer.wait_time = 1.1
	else:
		phase = 0
		fire_timer.wait_time = 1.6


func _on_fire_timer_timeout() -> void:
	match phase:
		0:
			_fire_spread(1, 0.0)
		1:
			_fire_spread(3, 40.0)
		_:
			_fire_spread(5, 70.0)


func _fire_spread(count: int, spread_degrees: float) -> void:
	var player := _get_player()
	var pool := _get_enemy_bullet_pool()
	if player == null or pool == null:
		return
	var base_angle := (player.global_position - muzzle.global_position).angle()
	var spread_rad := deg_to_rad(spread_degrees)
	for i in count:
		var t := 0.0 if count == 1 else (float(i) / float(count - 1)) - 0.5
		var angle := base_angle + t * spread_rad
		var direction := Vector2.RIGHT.rotated(angle)
		pool.fire(muzzle.global_position, direction, 130.0, 1)
	FxSpawner.spawn_muzzle_flash(get_tree(), muzzle.global_position, Vector2.RIGHT.rotated(base_angle))
