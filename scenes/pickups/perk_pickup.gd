extends Area2D

@export var perk_id: String = "jetpack"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_perk"):
		body.pickup_perk(perk_id)
		AudioManager.play(AudioManager.SFX_PICKUP)
		FxSpawner.spawn_hit(get_tree(), global_position, Color(0.6, 0.9, 1.0))
		queue_free()
