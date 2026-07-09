extends "res://scenes/levels/level_base.gd"

const GROUND_TOP_Y := 234.0


func _build_terrain() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": 300, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 300, "x_end": 350, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 350, "x_end": 650, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 650, "x_end": 730, "type": "water", "top_y": GROUND_TOP_Y},
		{"x_start": 730, "x_end": 950, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 950, "x_end": 1000, "type": "hole", "top_y": GROUND_TOP_Y},
		# Jump gauntlet: three small platforms over two pits.
		{"x_start": 1000, "x_end": 1032, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1032, "x_end": 1064, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 1064, "x_end": 1096, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1096, "x_end": 1128, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 1128, "x_end": 1160, "type": "ground", "top_y": GROUND_TOP_Y},
		# Mountain climb: ascend in 24px steps to a peak, then a wide descent
		# landing (not two narrow steps) so an extra jump off the peak can't
		# carry a player past the descent in one arc.
		{"x_start": 1160, "x_end": 1200, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1200, "x_end": 1240, "type": "ground", "top_y": GROUND_TOP_Y - 24},
		{"x_start": 1240, "x_end": 1280, "type": "ground", "top_y": GROUND_TOP_Y - 48},
		{"x_start": 1280, "x_end": 1360, "type": "ground", "top_y": GROUND_TOP_Y - 24},
		{"x_start": 1360, "x_end": 1640, "type": "ground", "top_y": GROUND_TOP_Y},
	]
	terrain_visual.build(spans)
