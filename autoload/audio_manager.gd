extends Node

## Small SFX pool: a single AudioStreamPlayer can only play one instance of
## a sound at a time, so overlapping gunfire/hits needs several player nodes
## to round-robin across.

## Kept small: on the Android OpenSL driver, more concurrent voices means
## more real-time mixing work per audio callback, and this project has hit
## a native crash (SIGSEGV in the AudioTrack thread, deep in Godot's own
## mixer) on real hardware during long play sessions. Fewer simultaneous
## voices reduces that load; it doesn't fix the underlying engine bug
## (unpatched upstream: godotengine/godot#121195) but lowers how much
## work the audio thread does per callback.
const POOL_SIZE := 4

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
