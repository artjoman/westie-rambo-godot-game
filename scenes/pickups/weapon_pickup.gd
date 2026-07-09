extends Area2D

@export var weapon_id: String = "spread"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_weapon"):
		body.pickup_weapon(weapon_id)
		AudioManager.play(AudioManager.SFX_PICKUP)
		FxSpawner.spawn_hit(get_tree(), global_position, Color(1.0, 0.85, 0.2))
		queue_free()
