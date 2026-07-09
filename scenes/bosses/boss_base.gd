extends CharacterBody2D

## Shared plumbing for every boss: health/hurtbox wiring, HUD boss-health-bar
## updates, phase-threshold dispatch, and death/score handling. Individual
## bosses override _on_ready_extra() and _update_phase() for their own attack
## patterns — this exists because turret.gd/soldier.gd already duplicate this
## wiring twice, and a 3rd-5th copy for bosses would be the point the plan
## itself flagged as "worth factoring out."

signal defeated

@export var score_value: int = 1000
@export var boss_max_health: int = 20

@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var visual: CanvasItem = $Visual

var phase := 0
var _player: Node2D = null
var _bullet_pool: Node = null


func _ready() -> void:
	add_to_group("boss")
	health_component.max_health = boss_max_health
	health_component.reset()
	hurtbox.hurt.connect(health_component.damage)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	_on_ready_extra()


func _on_ready_extra() -> void:
	pass # overridden by subclasses


func _update_phase(_current: int, _max_hp: int) -> void:
	pass # overridden by subclasses


func announce() -> void:
	var hud := _get_hud()
	if hud:
		hud.show_boss_health(health_component.current_health, health_component.max_health)


func _on_health_changed(current: int, max_hp: int) -> void:
	AudioManager.play(AudioManager.SFX_HIT)
	FxSpawner.spawn_hit(get_tree(), global_position)
	_flash_hit()
	var hud := _get_hud()
	if hud:
		hud.update_boss_health(current)
	var prev_phase := phase
	_update_phase(current, max_hp)
	if phase != prev_phase:
		var player := _get_player()
		if player and player.has_method("shake_camera"):
			player.shake_camera(4.0)


func _flash_hit() -> void:
	visual.modulate = Color(3.0, 3.0, 3.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0), 0.15)


func _on_died() -> void:
	AudioManager.play(AudioManager.SFX_EXPLOSION)
	FxSpawner.spawn_explosion(get_tree(), global_position)
	var player := _get_player()
	if player and player.has_method("shake_camera"):
		player.shake_camera(6.0)
	GameState.register_kill(score_value)
	defeated.emit()
	var hud := _get_hud()
	if hud:
		hud.hide_boss_health()
	queue_free()


func _get_hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player


func _get_enemy_bullet_pool() -> Node:
	if _bullet_pool == null or not is_instance_valid(_bullet_pool):
		_bullet_pool = get_tree().get_first_node_in_group("enemy_bullet_pool")
	return _bullet_pool


func _fire_at_player(muzzle: Marker2D, bullet_speed: float, damage: int) -> void:
	var player := _get_player()
	var pool := _get_enemy_bullet_pool()
	if player == null or pool == null:
		return
	var direction := (player.global_position - muzzle.global_position).normalized()
	pool.fire(muzzle.global_position, direction, bullet_speed, damage)
	FxSpawner.spawn_muzzle_flash(get_tree(), muzzle.global_position, direction)
