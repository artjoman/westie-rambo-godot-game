extends Area2D

## One shared scene for every weapon pickup; the icon is picked here by
## weapon_id rather than needing a separate .tscn per weapon type, mirroring
## player.gd's WEAPON_TIERS const-table pattern.
const AMMO_ICONS := {
	"spread": preload("res://assets/sprites/generated/ammo_spread.png"),
	"machine_gun": preload("res://assets/sprites/generated/ammo_machine_gun.png"),
	"laser": preload("res://assets/sprites/generated/ammo_laser.png"),
}

@export var weapon_id: String = "spread"

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	if AMMO_ICONS.has(weapon_id):
		sprite.texture = AMMO_ICONS[weapon_id]
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_weapon"):
		body.pickup_weapon(weapon_id)
		AudioManager.play(AudioManager.SFX_PICKUP)
		FxSpawner.spawn_hit(get_tree(), global_position, Color(1.0, 0.85, 0.2))
		queue_free()
