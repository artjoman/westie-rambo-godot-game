extends Node

## Small SFX pool: a single AudioStreamPlayer can only play one instance of
## a sound at a time, so overlapping gunfire/hits needs several player nodes
## to round-robin across.

const POOL_SIZE := 8

const SFX_SHOOT := preload("res://assets/audio/sfx/sfx_shoot.tres")
const SFX_SHOOT_SPREAD := preload("res://assets/audio/sfx/sfx_shoot_spread.tres")
const SFX_HIT := preload("res://assets/audio/sfx/sfx_hit.tres")
const SFX_EXPLOSION := preload("res://assets/audio/sfx/sfx_explosion.tres")
const SFX_PLAYER_HURT := preload("res://assets/audio/sfx/sfx_player_hurt.tres")
const SFX_PICKUP := preload("res://assets/audio/sfx/sfx_pickup.tres")
const SFX_JUMP := preload("res://assets/audio/sfx/sfx_jump.tres")
const SFX_LASER := preload("res://assets/audio/sfx/sfx_laser.tres")
const SFX_LAND := preload("res://assets/audio/sfx/sfx_land.tres")
const SFX_BULLET_IMPACT := preload("res://assets/audio/sfx/sfx_bullet_impact.tres")
const SFX_CALLOUT := preload("res://assets/audio/sfx/sfx_callout.tres")
const SFX_JETPACK := preload("res://assets/audio/sfx/sfx_jetpack.tres")
const SFX_SHIELD_BREAK := preload("res://assets/audio/sfx/sfx_shield_break.tres")
const SFX_FLASHBANG := preload("res://assets/audio/sfx/sfx_flashbang.tres")

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_players.append(player)


func play(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()
