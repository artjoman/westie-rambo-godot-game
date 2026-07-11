extends "res://scenes/bosses/boss_base.gd"

## Caricature human vet: throws syringes at the player, escalating from a
## single toss to a rapid volley as phases progress -- the same timed-fire/
## phase-threshold shape as boss_wall.gd. Single muzzle (one arm throwing),
## unlike boss_wall's 3-muzzle turret layout, since this reads as a person,
## not an emplacement. Reuses the shared _fire_at_player() helper: the
## level's EnemyProjectiles pool is configured with syringe_bullet.tscn as
## its bullet_scene, so no bespoke firing/pool code is needed here.

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer


func _on_ready_extra() -> void:
	fire_timer.timeout.connect(_on_fire_timer_timeout)


func _update_phase(current: int, max_hp: int) -> void:
	var pct := float(current) / float(max_hp)
	if pct <= 0.33:
		phase = 2
		fire_timer.wait_time = 0.55
	elif pct <= 0.66:
		phase = 1
		fire_timer.wait_time = 0.95
	else:
		phase = 0
		fire_timer.wait_time = 1.6


func _on_fire_timer_timeout() -> void:
	_fire_at_player(muzzle, 140.0, 1)
	if phase >= 1:
		await get_tree().create_timer(0.15).timeout
		_fire_at_player(muzzle, 140.0, 1)
	if phase >= 2:
		await get_tree().create_timer(0.15).timeout
		_fire_at_player(muzzle, 140.0, 1)
