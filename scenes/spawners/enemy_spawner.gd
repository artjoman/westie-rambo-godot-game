extends Marker2D

@export var wave: WaveData
@export var spawn_parent_path: NodePath = NodePath("..")

@onready var spawn_timer: Timer = $SpawnTimer

var _spawned_count := 0


func _ready() -> void:
	if wave == null or wave.enemy_scenes.is_empty():
		return
	spawn_timer.wait_time = wave.interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_one()
	if wave.count > 1:
		spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	_spawn_one()
	if _spawned_count >= wave.count:
		spawn_timer.stop()


func _spawn_one() -> void:
	var scene: PackedScene = wave.enemy_scenes[randi() % wave.enemy_scenes.size()]
	var enemy: Node2D = scene.instantiate()
	enemy.global_position = global_position
	# Deferred because the initial spawn-on-ready call can land while the
	# level's own scene tree is still assembling its children.
	get_node(spawn_parent_path).add_child.call_deferred(enemy)
	_spawned_count += 1
