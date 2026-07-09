extends Node2D

## Decorative background skirmish for the menu/win/game-over screens: a
## westie "Rambo" dog vs sneaky ninja cats. Fully self-starting from _ready()
## based on the exported mode - the three screen scripts never need to know
## this node exists.

enum Mode { SKIRMISH, VICTORY, DEFEAT }

const DOG_IDLE := preload("res://assets/sprites/generated/dog_hero_idle.png")
const DOG_SHOOT := preload("res://assets/sprites/generated/dog_hero_shoot.png")
# Reuses the large mega-cat boss sprites instead of the small dedicated
# ninja_cat art, so the backdrop cats read at the same scale/detail as the
# dog hero rather than looking like tiny mooks next to him.
const CAT_TEXTURES := [
	preload("res://assets/sprites/generated/boss_wall.png"),
	preload("res://assets/sprites/generated/boss_splitter.png"),
	preload("res://assets/sprites/generated/boss_chaser.png"),
]
const CAT_SCALE := Vector2(1.3, 1.3)
const SHURIKEN_TEX := preload("res://assets/sprites/generated/shuriken.png")

@export var mode: Mode = Mode.SKIRMISH

@onready var dog: Sprite2D = $Dog
@onready var cat_slot_left: Node2D = $CatSlotLeft
@onready var cat_slot_right: Node2D = $CatSlotRight
@onready var spawn_timer: Timer = $SpawnTimer

# Plain counters (not gameplay state, just cheap headless-verification hooks
# mirroring the rest of this project's scratch-driver introspection style).
var cat_spawn_count := 0
var throw_count := 0
var clash_count := 0
var dog_fire_count := 0
var poof_count := 0

var _slot_occupied := {}


func _ready() -> void:
	match mode:
		Mode.SKIRMISH:
			_start_skirmish()
		Mode.VICTORY:
			_start_victory()
		Mode.DEFEAT:
			_start_defeat()


func _pick_free_slot() -> Node2D:
	var slots: Array[Node2D] = [cat_slot_left, cat_slot_right]
	slots.shuffle()
	for s in slots:
		if not _slot_occupied.get(s, false):
			return s
	return null


func _spawn_cat(slot: Node2D) -> Sprite2D:
	var cat := Sprite2D.new()
	cat.texture = CAT_TEXTURES[randi() % CAT_TEXTURES.size()]
	cat.position = slot.position
	cat.scale = Vector2.ZERO
	cat.add_to_group("backdrop_cat")
	add_child(cat)
	cat_spawn_count += 1
	var tw := create_tween()
	tw.tween_property(cat, "scale", CAT_SCALE, 0.15)
	return cat


func _throw_shuriken(from_pos: Vector2, to_pos: Vector2) -> void:
	var shuriken := Sprite2D.new()
	shuriken.texture = SHURIKEN_TEX
	shuriken.global_position = from_pos
	add_child(shuriken)
	throw_count += 1

	var jittered_target := to_pos + Vector2(0, randf_range(-10.0, 10.0))
	var spin_tw := create_tween()
	spin_tw.set_loops()
	spin_tw.tween_property(shuriken, "rotation", TAU, 0.15).set_trans(Tween.TRANS_LINEAR)

	var move_tw := create_tween()
	move_tw.tween_property(shuriken, "global_position", jittered_target, 0.4).set_trans(Tween.TRANS_LINEAR)
	await move_tw.finished
	# Kill the infinite spin tween before freeing its target - an in-flight
	# looping tween on a freed node otherwise errors next time it ticks.
	spin_tw.kill()
	if is_instance_valid(shuriken):
		shuriken.queue_free()


func _cat_poof(cat: Sprite2D, slot: Node2D) -> void:
	if is_instance_valid(cat):
		FxSpawner.spawn_smoke_poof(get_tree(), cat.global_position)
		poof_count += 1
		cat.queue_free()
	_slot_occupied[slot] = false


func _dog_fire(direction: Vector2) -> void:
	dog.texture = DOG_SHOOT
	dog_fire_count += 1
	FxSpawner.spawn_muzzle_flash(get_tree(), dog.global_position, direction)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		dog.texture = DOG_IDLE


func _dog_flinch() -> void:
	dog.modulate = Color(3, 3, 3)
	var tw := create_tween()
	tw.tween_property(dog, "modulate", Color(1, 1, 1), 0.15)


# ---- SKIRMISH (main menu): continuous back-and-forth fight ----

func _start_skirmish() -> void:
	spawn_timer.wait_time = 2.2
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_skirmish_tick)
	spawn_timer.start()


func _on_skirmish_tick() -> void:
	var slot := _pick_free_slot()
	if slot == null:
		return
	_slot_occupied[slot] = true
	var cat := _spawn_cat(slot)

	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self) or not is_instance_valid(cat):
		_slot_occupied[slot] = false
		return
	var fire_dir := (dog.global_position - cat.global_position).normalized()

	await _throw_shuriken(cat.global_position, dog.global_position)
	if not is_instance_valid(self):
		return
	if randf() < 0.7:
		FxSpawner.spawn_hit(get_tree(), dog.global_position, Color(0.8, 0.85, 0.9))
		clash_count += 1
		_dog_fire(-fire_dir)
	_cat_poof(cat, slot)


# ---- VICTORY (win screen): cats flee/poof, dog is triumphant ----

func _start_victory() -> void:
	spawn_timer.wait_time = 3.0
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_victory_tick)
	spawn_timer.start()
	_start_dog_triumph_loop()


func _on_victory_tick() -> void:
	var slot := _pick_free_slot()
	if slot == null:
		return
	_slot_occupied[slot] = true
	var cat := _spawn_cat(slot)

	var away_sign := -1.0 if slot == cat_slot_left else 1.0
	var flee_target: Vector2 = slot.position + Vector2(40.0 * away_sign, 0.0)
	var flee_tw := create_tween()
	flee_tw.tween_property(cat, "position", flee_target, 0.5)

	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self):
		_cat_poof(cat, slot)


func _start_dog_triumph_loop() -> void:
	var puff_timer := Timer.new()
	puff_timer.wait_time = 2.0
	add_child(puff_timer)
	puff_timer.timeout.connect(func() -> void:
		var tw := create_tween()
		tw.tween_property(dog, "scale", Vector2(1.1, 1.1), 0.15)
		tw.tween_property(dog, "scale", Vector2(1.0, 1.0), 0.15)
	)
	puff_timer.start()

	var shot_timer := Timer.new()
	shot_timer.wait_time = 5.5
	add_child(shot_timer)
	shot_timer.timeout.connect(func() -> void:
		_dog_fire(Vector2.UP)
	)
	shot_timer.start()


# ---- DEFEAT (game over screen): cats cocky, dog dazed, never fires back ----

func _start_defeat() -> void:
	spawn_timer.wait_time = 2.5
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_defeat_tick)
	spawn_timer.start()
	_start_dog_woozy_loop()


func _on_defeat_tick() -> void:
	var slot := _pick_free_slot()
	if slot == null:
		return
	_slot_occupied[slot] = true
	var cat := _spawn_cat(slot)

	if randf() < 0.33:
		await get_tree().create_timer(0.3).timeout
		if not is_instance_valid(self) or not is_instance_valid(cat):
			_slot_occupied[slot] = false
			return
		await _throw_shuriken(cat.global_position, dog.global_position)
		if is_instance_valid(self):
			_dog_flinch()
		_cat_poof(cat, slot)
	else:
		var hop_tw := create_tween()
		hop_tw.set_loops(2)
		hop_tw.tween_property(cat, "position:y", slot.position.y - 6.0, 0.2)
		hop_tw.tween_property(cat, "position:y", slot.position.y, 0.2)
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			_cat_poof(cat, slot)


func _start_dog_woozy_loop() -> void:
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(dog, "rotation", 0.08, 1.2)
	tw.tween_property(dog, "rotation", -0.08, 1.2)
