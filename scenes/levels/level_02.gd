extends "res://scenes/levels/level_base.gd"

const GROUND_TOP_Y := 234.0


func _build_terrain() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": 250, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 250, "x_end": 300, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 300, "x_end": 500, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 500, "x_end": 600, "type": "water", "top_y": GROUND_TOP_Y},
		{"x_start": 600, "x_end": 850, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 850, "x_end": 900, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 900, "x_end": 1150, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1150, "x_end": 1200, "type": "water", "top_y": GROUND_TOP_Y},
		# Jump gauntlet: three small platforms over two pits.
		{"x_start": 1200, "x_end": 1232, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1232, "x_end": 1264, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 1264, "x_end": 1296, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1296, "x_end": 1328, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 1328, "x_end": 1360, "type": "ground", "top_y": GROUND_TOP_Y},
		# Mountain climb: ascend in 24px steps to a peak, then a wide descent
		# landing (not two narrow steps) so an extra jump off the peak can't
		# carry a player past the descent in one arc.
		{"x_start": 1360, "x_end": 1400, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 1400, "x_end": 1440, "type": "ground", "top_y": GROUND_TOP_Y - 24},
		{"x_start": 1440, "x_end": 1480, "type": "ground", "top_y": GROUND_TOP_Y - 48},
		{"x_start": 1480, "x_end": 1560, "type": "ground", "top_y": GROUND_TOP_Y - 24},
		{"x_start": 1560, "x_end": 1760, "type": "ground", "top_y": GROUND_TOP_Y},
	]
	terrain_visual.build(spans)
