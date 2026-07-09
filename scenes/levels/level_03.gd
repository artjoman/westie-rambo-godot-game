extends "res://scenes/levels/level_base.gd"

const GROUND_TOP_Y := 234.0


func _build_terrain() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": 200, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 200, "x_end": 260, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 260, "x_end": 500, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 500, "x_end": 620, "type": "water", "top_y": GROUND_TOP_Y},
		{"x_start": 620, "x_end": 900, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 900, "x_end": 950, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 950, "x_end": 1200, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1200, "x_end": 1280, "type": "water", "top_y": GROUND_TOP_Y},
		# Jump gauntlet: three small platforms over two pits.
		{"x_start": 1280, "x_end": 1312, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1312, "x_end": 1344, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 1344, "x_end": 1376, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1376, "x_end": 1408, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 1408, "x_end": 1440, "type": "ground", "top_y": GROUND_TOP_Y},
		# Mountain climb: ascend in 24px steps to a peak, then a wide descent
		# landing (not two narrow steps) so an extra jump off the peak can't
		# carry a player past the descent in one arc.
		{"x_start": 1440, "x_end": 1480, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1480, "x_end": 1520, "type": "ground", "top_y": GROUND_TOP_Y - 24},
		{"x_start": 1520, "x_end": 1560, "type": "ground", "top_y": GROUND_TOP_Y - 48},
		{"x_start": 1560, "x_end": 1640, "type": "ground", "top_y": GROUND_TOP_Y - 24},
		{"x_start": 1640, "x_end": 1860, "type": "ground", "top_y": GROUND_TOP_Y},
	]
	terrain_visual.build(spans)
