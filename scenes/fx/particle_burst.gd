extends GPUParticles2D

## Shared by hit_spark.tscn and explosion.tscn — each configures its own
## ParticleProcessMaterial/amount/lifetime, this just frees the node once
## its one-shot burst finishes so callers never have to remember to clean up.


func _ready() -> void:
	finished.connect(queue_free)
