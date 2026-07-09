extends Area2D

# Backstop cleanup independent of screen visibility. VisibleOnScreenNotifier2D
# handles the common case cheaply, but its signals depend on the rendering
# server's culling and aren't guaranteed to fire in every context (headless
# runs, minimized windows) — without this, a missed signal would leak a
# pooled bullet forever.
const MAX_LIFETIME := 2.5

@export var impact_tint: Color = Color(1, 1, 1)

var direction := Vector2.RIGHT
var speed := 260.0
var damage := 1
var active := false
var _lifetime := 0.0

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	screen_notifier.screen_exited.connect(deactivate)
	deactivate()


func _physics_process(delta: float) -> void:
	if not active:
		return
	position += direction * speed * delta
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		deactivate()


func activate(spawn_position: Vector2, aim: Vector2, bullet_speed: float, bullet_damage: int) -> void:
	global_position = spawn_position
	direction = aim.normalized()
	speed = bullet_speed
	damage = bullet_damage
	rotation = direction.angle()
	_lifetime = 0.0
	active = true
	visible = true
	monitoring = true
	monitorable = true


func deactivate() -> void:
	active = false
	visible = false
	# deferred: deactivate() runs inside area_entered/body_entered handling,
	# and Godot blocks synchronous monitoring/monitorable writes mid-signal.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _on_hit(other: Node) -> void:
	if not active:
		return
	if other.has_method("damage"):
		other.damage(damage)
	FxSpawner.spawn_hit(get_tree(), global_position, impact_tint)
	AudioManager.play(AudioManager.SFX_BULLET_IMPACT, -6.0)
	deactivate()
