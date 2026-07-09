extends "res://scenes/bosses/boss_base.gd"

## Alternates chasing the player horizontally with sudden charge dashes,
## while firing periodically. Gets faster and charges more often below 40%
## health. Meant to force platforming/dodging rather than just trading shots.

@export var chase_speed: float = 50.0
@export var charge_speed: float = 140.0
@export var arena_left: float = 0.0
@export var arena_right: float = 300.0

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer
@onready var charge_timer: Timer = $ChargeTimer

enum BossState { CHASE, CHARGE }
var boss_state := BossState.CHASE
var _charge_dir := 1


func _on_ready_extra() -> void:
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	charge_timer.timeout.connect(_on_charge_timer_timeout)


func _update_phase(current: int, max_hp: int) -> void:
	var pct := float(current) / float(max_hp)
	phase = 1 if pct <= 0.4 else 0
	charge_speed = 200.0 if phase == 1 else 140.0
	charge_timer.wait_time = 1.6 if phase == 1 else 2.5


func _physics_process(delta: float) -> void:
	var player := _get_player()
	if player == null:
		return

	match boss_state:
		BossState.CHASE:
			var dir_x := signf(player.global_position.x - global_position.x)
			global_position.x += dir_x * chase_speed * delta
		BossState.CHARGE:
			global_position.x += _charge_dir * charge_speed * delta

	global_position.x = clamp(global_position.x, arena_left, arena_right)


func _on_charge_timer_timeout() -> void:
	var player := _get_player()
	if player == null:
		return
	_charge_dir = int(signf(player.global_position.x - global_position.x))
	if _charge_dir == 0:
		_charge_dir = 1
	boss_state = BossState.CHARGE
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		boss_state = BossState.CHASE


func _on_fire_timer_timeout() -> void:
	_fire_at_player(muzzle, 160.0, 1)
