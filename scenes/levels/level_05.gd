extends "res://scenes/levels/level_base.gd"

## Fully underwater level: the whole playable column is one WaterZone (not
## the usual brief pool hazard), so the player is in swim mode - gentle
## sink gravity + swim-kick jump - for the entire level instead of normal
## platform gravity. A sandy seafloor and a few reef platforms give
## occasional solid footing, but swimming is the primary mode throughout.

const WATER_TOP_Y := 50.0
const FLOOR_TOP_Y := 234.0
const LEVEL_WIDTH := 1400


func _build_terrain() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": LEVEL_WIDTH, "type": "water", "top_y": WATER_TOP_Y},
		{"x_start": 0, "x_end": LEVEL_WIDTH, "type": "ground", "top_y": FLOOR_TOP_Y},
		{"x_start": 300, "x_end": 360, "type": "ground", "top_y": 170.0},
		{"x_start": 700, "x_end": 760, "type": "ground", "top_y": 140.0},
		{"x_start": 1050, "x_end": 1110, "type": "ground", "top_y": 180.0},
	]
	terrain_visual.build(spans)
