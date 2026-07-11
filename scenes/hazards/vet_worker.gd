extends Node2D

## Purely decorative background NPC: deliberately no CollisionShape2D/Area2D/
## CharacterBody2D anywhere on this node, so it genuinely cannot be shot,
## collided with, or interacted with -- matching the design intent exactly
## ("cannot shoot or interact or run away"). Idles via a looping Tween the
## same way battle_backdrop.gd's decorative sprites do; the level calls
## play_lunge() once, when the capture encounter it triggers begins, for a
## single non-looping "catch" beat that reads as the moment the westie gets
## grabbed.

@onready var sprite: Sprite2D = $Sprite

var _base_y: float
var _idle_tween: Tween


func _ready() -> void:
	_base_y = sprite.position.y
	_start_idle()


func _start_idle() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	sprite.position.y = _base_y
	sprite.scale = Vector2.ONE
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "position:y", _base_y - 3.0, 0.6).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "position:y", _base_y, 0.6).set_trans(Tween.TRANS_SINE)


func play_lunge() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	sprite.position.y = _base_y
	var lunge := create_tween()
	lunge.tween_property(sprite, "scale", Vector2(1.3, 0.8), 0.15)
	lunge.tween_property(sprite, "scale", Vector2.ONE, 0.25)
	lunge.tween_callback(_start_idle)
