extends Area2D

## Detection-only damage receiver, separate from an entity's solid collision
## body. Bullets duck-type against `damage()` (see bullet.gd's _on_hit), so a
## Hurtbox just needs to expose that method and forward it to whichever
## HealthComponent its owning entity connects it to.

signal hurt(amount: int)


func damage(amount: int) -> void:
	hurt.emit(amount)
