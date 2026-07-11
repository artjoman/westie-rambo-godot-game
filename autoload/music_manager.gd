extends Node

## Procedurally synthesized background music (no internet access for real
## music files, so tracks are generated from raw waveforms at startup, the
## same technique audio_manager.gd uses for SFX — just sequenced into looping
## melodies here instead of one-shot blips). Two AudioStreamPlayers let
## MusicManager crossfade between tracks instead of hard-cutting.

const MIX_RATE := 22050
const CROSSFADE_TIME := 1.0
const MUSIC_VOLUME_DB := -6.0

var _players: Array[AudioStreamPlayer] = []
var _active_index := 0
var _current_track := ""
var _crossfade_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)


func play_menu() -> void:
	_crossfade_to("menu", _build_menu_theme())


func play_level() -> void:
	_crossfade_to("level", _build_level_theme())


func play_boss() -> void:
	_crossfade_to("boss", _build_boss_theme())


func _crossfade_to(track_name: String, stream: AudioStreamWAV) -> void:
	if track_name == _current_track:
		return
	_current_track = track_name

	# A player slot gets reused for whatever track plays next. If a previous
	# crossfade's tween is still in flight, its chained stop() callback is
	# bound to that player node and fires later regardless — so once the
	# slot is reassigned to a new track, the stale callback silences the
	# new track instead of the one it was meant for. Killing any in-flight
	# tween up front prevents that stale callback from ever firing.
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	var outgoing: AudioStreamPlayer = _players[_active_index]
	_active_index = 1 - _active_index
	var incoming: AudioStreamPlayer = _players[_active_index]

	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(incoming, "volume_db", MUSIC_VOLUME_DB, CROSSFADE_TIME)
	_crossfade_tween.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_TIME)
	_crossfade_tween.chain().tween_callback(outgoing.stop)


# --- Track definitions ---
# Each track is a short looping [lead melody + bass line] pair. Both voices
# must sum to the same total duration so they tile together seamlessly —
# enforced by construction (matching beat counts) rather than checked at
# runtime, since these are fixed, hand-picked note sequences.

func _build_menu_theme() -> AudioStreamWAV:
	var beat := 60.0 / 100.0 # 100 BPM, calm
	var lead := [
		[523.25, 1.0], [659.25, 1.0], [783.99, 1.0], [659.25, 1.0],
		[587.33, 1.0], [698.46, 1.0], [880.00, 1.0], [698.46, 1.0],
	]
	var bass := [[130.81, 4.0], [174.61, 4.0]]
	return _generate_track(lead, bass, beat, "sine", "triangle", 0.35, 0.2)


func _build_level_theme() -> AudioStreamWAV:
	var beat := 60.0 / 150.0 # 150 BPM, driving
	var lead := [
		[659.25, 0.5], [783.99, 0.5], [659.25, 0.5], [880.00, 0.5],
		[659.25, 0.5], [783.99, 0.5], [659.25, 0.5], [987.77, 0.5],
	]
	var bass := [
		[82.41, 0.5], [82.41, 0.5], [82.41, 0.5], [82.41, 0.5],
		[82.41, 0.5], [82.41, 0.5], [82.41, 0.5], [82.41, 0.5],
	]
	return _generate_track(lead, bass, beat, "square", "square", 0.3, 0.25)


func _build_boss_theme() -> AudioStreamWAV:
	var beat := 60.0 / 175.0 # 175 BPM, tense
	var lead := [
		[587.33, 0.5], [415.30, 0.5], [587.33, 0.5], [698.46, 0.5],
		[587.33, 0.5], [415.30, 0.5], [587.33, 0.5], [523.25, 0.5],
	]
	var bass := [
		[73.42, 0.5], [73.42, 0.5], [73.42, 0.5], [73.42, 0.5],
		[73.42, 0.5], [73.42, 0.5], [73.42, 0.5], [73.42, 0.5],
	]
	return _generate_track(lead, bass, beat, "square", "square", 0.32, 0.28)


## Extra samples appended after loop_end, duplicating the start of the loop.
## A WAV loaded from disk gets this padding added transparently by Godot's
## importer, because the mixer's resampler reads a few samples *ahead* of
## the current playback position for interpolation and needs real backing
## data there even right at the loop seam. A stream built by hand via
## `stream.data = ...` (as here) never gets that padding -- so on real
## Android hardware, the first loop wrap (a few seconds in, matching when
## this game was crashing on device) could read past the buffer's actual
## end. Padding it ourselves closes that gap.
const LOOP_GUARD_SAMPLES := 8

func _generate_track(lead_notes: Array, bass_notes: Array, beat_duration: float, lead_wave: String, bass_wave: String, lead_volume: float, bass_volume: float) -> AudioStreamWAV:
	var lead_samples := _build_voice(lead_notes, beat_duration, lead_wave, lead_volume)
	var bass_samples := _build_voice(bass_notes, beat_duration, bass_wave, bass_volume)
	var sample_count: int = min(lead_samples.size(), bass_samples.size())
	var guard_count: int = min(LOOP_GUARD_SAMPLES, sample_count)

	var data := PackedByteArray()
	data.resize((sample_count + guard_count) * 2)
	for i in sample_count:
		var mixed: float = clamp(lead_samples[i] + bass_samples[i], -1.0, 1.0)
		data.encode_s16(i * 2, int(mixed * 32767))
	for i in guard_count:
		# Duplicate the loop's opening samples right after loop_end, so
		# post-wrap interpolation reads real (correct) data instead of
		# running off the end of the buffer.
		var mixed: float = clamp(lead_samples[i] + bass_samples[i], -1.0, 1.0)
		data.encode_s16((sample_count + i) * 2, int(mixed * 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


## Builds one voice's full sample buffer as floats in [-1, 1], continuous
## phase across notes (no clicking from frequency jumps) plus a short
## per-note envelope (so note *boundaries* don't click either).
func _build_voice(notes: Array, beat_duration: float, wave_type: String, volume: float) -> PackedFloat32Array:
	const ENVELOPE_TIME := 0.015

	# Pre-sized and index-assigned rather than grown via repeated .append() --
	# a real Xiaomi/MIUI device crashed reliably ~5s into boot (SIGSEGV,
	# tag-mismatched pointer, on whichever thread next touched the heap)
	# while this ran, appending 100k+ samples one at a time. Computing the
	# total length up front and resizing once avoids the repeated CowData
	# grow/copy that pattern causes.
	var total_samples := 0
	for note in notes:
		var duration: float = note[1] * beat_duration
		total_samples += int(duration * MIX_RATE)

	var samples := PackedFloat32Array()
	samples.resize(total_samples)

	var phase := 0.0
	var out_i := 0

	for note in notes:
		var freq: float = note[0]
		var duration: float = note[1] * beat_duration
		var note_sample_count := int(duration * MIX_RATE)
		var envelope_samples := int(ENVELOPE_TIME * MIX_RATE)

		for i in note_sample_count:
			var raw: float
			if freq <= 0.0:
				raw = 0.0
			else:
				phase += freq / MIX_RATE
				match wave_type:
					"square":
						raw = 1.0 if sin(TAU * phase) >= 0.0 else -1.0
					"triangle":
						raw = 2.0 * abs(2.0 * (phase - floor(phase + 0.5))) - 1.0
					_:
						raw = sin(TAU * phase)

			var envelope := 1.0
			if i < envelope_samples:
				envelope = float(i) / envelope_samples
			elif i > note_sample_count - envelope_samples:
				envelope = float(note_sample_count - i) / envelope_samples

			samples[out_i] = raw * volume * envelope
			out_i += 1

	return samples
