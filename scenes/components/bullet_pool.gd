extends Node2D

## Reusable projectile pool. Lives inside a level scene (not an autoload) so
## pooled bullets are cleaned up automatically when the level unloads.
## Callers find it via group membership rather than a direct reference, so
## bullet-firing scenes (player, enemies) stay decoupled from level layout.
## group_name lets a level host separate pools for player vs. enemy fire.

@export var bullet_scene: PackedScene
@export var initial_size: int = 24
@export var group_name: String = "bullet_pool"

var _bullets: Array[Node] = []


func _ready() -> void:
	add_to_group(group_name)
	for i in initial_size:
		_bullets.append(_spawn_bullet())


func fire(spawn_position: Vector2, direction: Vector2, speed: float, damage: int) -> void:
	var bullet := _get_free_bullet()
	bullet.activate(spawn_position, direction, speed, damage)


func _get_free_bullet() -> Node:
	for bullet in _bullets:
		if not bullet.active:
			return bullet
	var bullet := _spawn_bullet()
	_bullets.append(bullet)
	return bullet


func _spawn_bullet() -> Node:
	var bullet: Node = bullet_scene.instantiate()
	add_child(bullet)
	return bullet
