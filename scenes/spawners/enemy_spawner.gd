extends Marker2D

## Emitted right after each enemy is spawned (before the deferred add_child
## actually lands), so a level can hook per-enemy signals -- e.g. connecting
## tree_exited to know when a whole encounter's enemies are cleared, the way
## level_06.gd tracks its capture-encounter waves.
signal spawned(enemy: Node2D)

@export var wave: WaveData
@export var spawn_parent_path: NodePath = NodePath("..")
## When true (default, matches every existing spawner's behavior), spawning
## begins the moment this node enters the tree. Set false for a spawner that
## should stay dormant until something else calls start() -- e.g. a
## wave-defense encounter that shouldn't fire on level load, only once the
## player is captured.
@export var auto_start := true

@onready var spawn_timer: Timer = $SpawnTimer

var _spawned_count := 0
var _started := false


func _ready() -> void:
	if auto_start:
		start()


## Begins spawning. Safe to call more than once (a no-op after the first).
func start() -> void:
	if _started:
		return
	_started = true
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
	spawned.emit(enemy)
	_spawned_count += 1
