extends "res://scenes/levels/level_base.gd"

## Vertical cliff climb: the player ascends a zigzagging shaft of ledges
## instead of scrolling left-to-right. Ledge positions are generated once
## into _ledges and used to build BOTH the terrain_visual spans and the
## matching collision bodies from the same data, so a long zigzagging
## sequence can't drift out of sync the way hand-authoring two parallel
## lists (one in this script, one in the .tscn) risks for this many ledges.
##
## Two clearance rules keep the player's 18px-tall collision box from
## getting wedged against the ledge above whatever they're standing on:
## 1. Consecutive climbing ledges never overlap in x (zigzag amplitude is
##    wider than half their combined width), so there's no ceiling directly
##    above a takeoff point at all for the normal climb.
## 2. The two transitions onto/off the wide base and peak platforms CAN'T
##    avoid some x-overlap with the adjacent ledge (the platforms are
##    deliberately wide), so those two specific jumps get extra rise and the
##    ledges are shallow (LEDGE_COLLISION_DEPTH), keeping (rise - depth)
##    comfortably above player height instead of the ~6px this design
##    started with (which pinned the player in overlapping solid geometry
##    from the very first jump - confirmed by a headless physics test that
##    showed on_floor staying true and position frozen despite nonzero
##    velocity every frame).

const GROUND_TOP_Y := 234.0
const LEDGE_COUNT := 20
const LEDGE_RISE := 22.0
const WIDE_PLATFORM_RISE := 30.0
const LEDGE_WIDTH := 60.0
const ZIGZAG := 40.0
const CENTER_X := 240.0
const BASE_WIDTH := 200.0
const PEAK_WIDTH := 220.0
const LEDGE_COLLISION_DEPTH := 8.0

var _ledges: Array[Dictionary] = []


func _build_terrain() -> void:
	_ledges.clear()
	_ledges.append({"x_center": CENTER_X, "top_y": GROUND_TOP_Y, "width": BASE_WIDTH})

	var current_top_y := GROUND_TOP_Y
	for i in LEDGE_COUNT:
		var rise: float = WIDE_PLATFORM_RISE if i == 0 else LEDGE_RISE
		current_top_y -= rise
		var side := -1.0 if i % 2 == 0 else 1.0
		var x_center: float = CENTER_X + side * ZIGZAG
		_ledges.append({"x_center": x_center, "top_y": current_top_y, "width": LEDGE_WIDTH})

	current_top_y -= WIDE_PLATFORM_RISE
	_ledges.append({"x_center": CENTER_X, "top_y": current_top_y, "width": PEAK_WIDTH})

	var spans: Array[Dictionary] = []
	for ledge in _ledges:
		var half_w: float = ledge["width"] / 2.0
		spans.append({
			"x_start": int(ledge["x_center"] - half_w),
			"x_end": int(ledge["x_center"] + half_w),
			"type": "ground",
			"top_y": ledge["top_y"],
		})
	terrain_visual.build(spans)
	_build_ledge_collisions()


func _build_ledge_collisions() -> void:
	for ledge in _ledges:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector2(ledge["x_center"], float(ledge["top_y"]) + LEDGE_COLLISION_DEPTH / 2.0)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(ledge["width"], LEDGE_COLLISION_DEPTH)
		shape.shape = rect
		body.add_child(shape)
		add_child(body)


## Standing height (matches the -9.0748 offset every hand-placed pickup/enemy
## in the other 3 levels uses relative to a ledge's top_y) for a given ledge
## index - 0 is the base, LEDGE_COUNT+1 is the peak.
func ledge_stand_position(index: int) -> Vector2:
	var ledge: Dictionary = _ledges[index]
	return Vector2(ledge["x_center"], float(ledge["top_y"]) - 9.0748)
