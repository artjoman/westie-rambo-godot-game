extends "res://scenes/levels/level_base.gd"

## The Groomer's Salon: a momentum-control level built around one new
## mechanic done well (soap-suds sliding) rather than several stacked at
## once. The first suds patch leads right up to a pit, so overshooting a
## slide has a real, fair consequence (respawn, same as any other hazard)
## instead of being a pure novelty. A second suds patch feeds directly into
## a pulsing blow-dryer gust further on -- sliding into a gust you can't
## fully control is the level's signature moment. Ends in a caricature
## groomer boss who fans out air-puff volleys instead of boss_vet's
## repeated-single-shot pattern.

const GROUND_TOP_Y := 234.0
const LEVEL_WIDTH := 1400


func _build_terrain() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": 380, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 380, "x_end": 420, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 420, "x_end": LEVEL_WIDTH, "type": "ground", "top_y": GROUND_TOP_Y},
	]
	terrain_visual.build(spans)
