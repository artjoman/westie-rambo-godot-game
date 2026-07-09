extends Node2D

const GROUND_TOP_Y := 234.0
const KILL_FLOOR_Y := 600.0

@onready var terrain_visual: Node2D = $TerrainVisual

var _player: Node = null


func _ready() -> void:
	var spans: Array[Dictionary] = [
		{"x_start": 0, "x_end": 176, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 176, "x_end": 240, "type": "hole", "top_y": GROUND_TOP_Y},
		{"x_start": 240, "x_end": 320, "type": "ground", "top_y": GROUND_TOP_Y},
		{"x_start": 320, "x_end": 400, "type": "water", "top_y": GROUND_TOP_Y},
		{"x_start": 400, "x_end": 480, "type": "ground", "top_y": GROUND_TOP_Y},
	]
	terrain_visual.build(spans)


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player and _player.global_position.y > KILL_FLOOR_Y:
		_player.respawn()
