extends Resource

class_name WaveData

## Data-driven wave definition: what spawns, how many, how often.
## New waves are new .tres instances, not new code.

@export var enemy_scenes: Array[PackedScene] = []
@export var count: int = 3
@export var interval: float = 1.5
