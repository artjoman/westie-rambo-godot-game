extends Resource

class_name WeaponData

## Data-driven weapon definition. New weapons/upgrade tiers are new .tres
## files, not new code — player.gd reads whichever WeaponData is active and
## fires generically off these fields.

@export var weapon_id: String = "pistol"
@export var display_name: String = "Pistol"
@export var level: int = 1

@export_group("Firing")
@export var fire_rate: float = 6.0
@export var bullet_speed: float = 260.0
@export var damage: int = 1
@export var bullets_per_shot: int = 1
@export var spread_angle_degrees: float = 0.0

@export_group("Beam (laser only)")
@export var is_beam: bool = false
@export var beam_range: float = 200.0
@export var beam_tick_interval: float = 0.1
@export var beam_color: Color = Color(0.4, 0.9, 1.0)

@export_group("Presentation")
@export var muzzle_color: Color = Color(1, 0.9, 0.2)
