extends RefCounted

class_name FxSpawner

const HIT_SPARK := preload("res://scenes/fx/hit_spark.tscn")
const EXPLOSION := preload("res://scenes/fx/explosion.tscn")
const MUZZLE_FLASH := preload("res://scenes/fx/muzzle_flash.tscn")
const DUST_PUFF := preload("res://scenes/fx/dust_puff.tscn")
const SMOKE_POOF := preload("res://scenes/fx/smoke_poof.tscn")
const FLASHBANG_FLASH := preload("res://scenes/fx/flashbang_flash.tscn")


static func spawn_hit(tree: SceneTree, global_pos: Vector2, tint: Color = Color(1, 1, 1)) -> void:
	var fx: Node2D = HIT_SPARK.instantiate()
	fx.global_position = global_pos
	fx.modulate = tint
	# Deferred: callers can trigger this from inside a physics/area signal
	# (e.g. water_zone.gd's body_exited) while the scene tree is mid-update,
	# which a direct add_child() rejects with "Parent node is busy".
	tree.current_scene.add_child.call_deferred(fx)


static func spawn_explosion(tree: SceneTree, global_pos: Vector2) -> void:
	var fx: Node2D = EXPLOSION.instantiate()
	fx.global_position = global_pos
	tree.current_scene.add_child.call_deferred(fx)


static func spawn_muzzle_flash(tree: SceneTree, global_pos: Vector2, direction: Vector2) -> void:
	var fx: Node2D = MUZZLE_FLASH.instantiate()
	fx.global_position = global_pos
	fx.rotation = direction.angle()
	tree.current_scene.add_child.call_deferred(fx)


static func spawn_dust(tree: SceneTree, global_pos: Vector2) -> void:
	var fx: Node2D = DUST_PUFF.instantiate()
	fx.global_position = global_pos
	tree.current_scene.add_child.call_deferred(fx)


static func spawn_smoke_poof(tree: SceneTree, global_pos: Vector2) -> void:
	var fx: Node2D = SMOKE_POOF.instantiate()
	fx.global_position = global_pos
	tree.current_scene.add_child.call_deferred(fx)


static func spawn_flashbang(tree: SceneTree, global_pos: Vector2) -> void:
	var fx: Node2D = FLASHBANG_FLASH.instantiate()
	fx.global_position = global_pos
	tree.current_scene.add_child.call_deferred(fx)
