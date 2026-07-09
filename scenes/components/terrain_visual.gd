extends Node2D

## Tiles placeholder textures across ground spans by instancing Sprite2D nodes
## in a grid. This stands in for a real TileSet/TileMapLayer (Milestone 5) —
## it's deliberately simple so hand-authoring terrain in a scene file doesn't
## require wrestling with TileMapLayer's packed cell-data format before real
## art and a proper tileset exist.

const TILE_SIZE := 16

@export var grass_texture: Texture2D
@export var dirt_texture: Texture2D
@export var water_texture: Texture2D
@export var hole_texture: Texture2D

## Each entry: {x_start, x_end, type, top_y} where type is "ground", "water",
## or "hole". top_y is per-span (not a single level-wide value) so a level
## can mix flat ground with elevated platforms/staircases in one build() call.
## dirt/hole fill down from top_y for dirt_depth tiles.
@export var dirt_depth: int = 3
## Water pools render deeper than normal ground — a few rows of water down to
## a visible floor tile — to match the actual recessed pool collision (see
## level_0N.tscn's WaterZone + pool-floor StaticBody2D).
@export var water_depth: int = 3
var spans: Array[Dictionary] = []


func build(terrain_spans: Array[Dictionary]) -> void:
	spans = terrain_spans
	for child in get_children():
		child.queue_free()

	for span in spans:
		var x_start: int = span.x_start
		var x_end: int = span.x_end
		var type: String = span.type
		var top_y: float = span.top_y
		var width := x_end - x_start
		var full_tile_count := width / TILE_SIZE
		var remainder := width - full_tile_count * TILE_SIZE

		for i in full_tile_count:
			_place_column(type, x_start + i * TILE_SIZE, top_y, 1.0)

		# GDScript's integer division above truncates any remainder, which
		# would otherwise leave a few untiled (transparent) pixels at the
		# right edge of almost every span — most visible as a "gap" where a
		# water span meets the ground beside it. A width-scaled partial tile
		# closes it exactly, with no overlap into the next span.
		if remainder > 0:
			_place_column(type, x_start + full_tile_count * TILE_SIZE, top_y, remainder / float(TILE_SIZE))


func _place_column(type: String, x: int, top_y: float, width_scale: float) -> void:
	if type == "hole":
		_place_tile(hole_texture, x, top_y, 0, width_scale)
		_place_tile(hole_texture, x, top_y, 1, width_scale)
	elif type == "water":
		for d in range(0, water_depth - 1):
			_place_tile(water_texture, x, top_y, d, width_scale)
		_place_tile(dirt_texture, x, top_y, water_depth - 1, width_scale)
	else:
		_place_tile(grass_texture, x, top_y, 0, width_scale)
		for d in range(1, dirt_depth):
			_place_tile(dirt_texture, x, top_y, d, width_scale)


func _place_tile(texture: Texture2D, x: int, top_y: float, row: int, width_scale: float = 1.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(x, top_y + row * TILE_SIZE)
	sprite.scale.x = width_scale
	add_child(sprite)
