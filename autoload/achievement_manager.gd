extends Node

## Single source of truth for achievement definitions and unlock rules —
## mirrors player.gd's WEAPON_TIERS const-table pattern (one place to tune
## thresholds instead of scattering them across level scenes).
##
## v1 scope is skill-challenges only: a "Flawless" and "Speedrun" pair per
## level. "Flawless" means the player didn't lose a life that level (driven
## by level_base.gd's existing player.respawned hookup), not literally "took
## zero damage" — a shield-absorbed or non-lethal hit doesn't disqualify it.

signal achievement_unlocked(id: String)

const FLAWLESS_PREFIX := "flawless_level_"
const SPEEDRUN_PREFIX := "speedrun_level_"

## First-guess targets in seconds, NOT playtested — play each level once at a
## brisk pace, note the actual clear time, and set these to ~1.15-1.3x that.
const SPEEDRUN_TARGET_SEC := [45.0, 50.0, 65.0, 60.0, 50.0]

const DEFINITIONS := {
	"flawless_level_0": {"title": "Flawless: Level 1", "description": "Clear Level 1 without losing a life."},
	"flawless_level_1": {"title": "Flawless: Level 2", "description": "Clear Level 2 without losing a life."},
	"flawless_level_2": {"title": "Flawless: Level 3", "description": "Clear Level 3 without losing a life."},
	"flawless_level_3": {"title": "Flawless: Level 4", "description": "Clear Level 4 without losing a life."},
	"flawless_level_4": {"title": "Flawless: Level 5", "description": "Clear Level 5 without losing a life."},
	"speedrun_level_0": {"title": "Speedrun: Level 1", "description": "Clear Level 1 in under 45s."},
	"speedrun_level_1": {"title": "Speedrun: Level 2", "description": "Clear Level 2 in under 50s."},
	"speedrun_level_2": {"title": "Speedrun: Level 3", "description": "Clear Level 3 in under 65s."},
	"speedrun_level_3": {"title": "Speedrun: Level 4", "description": "Clear Level 4 in under 60s."},
	"speedrun_level_4": {"title": "Speedrun: Level 5", "description": "Clear Level 5 in under 50s."},
}

## Explicit display order for the achievements screen, rather than relying
## on Dictionary iteration order.
const ORDER := [
	"flawless_level_0", "flawless_level_1", "flawless_level_2", "flawless_level_3", "flawless_level_4",
	"speedrun_level_0", "speedrun_level_1", "speedrun_level_2", "speedrun_level_3", "speedrun_level_4",
]


func report_level_cleared(level_index: int, elapsed_sec: float, died: bool) -> void:
	if not died:
		_unlock(FLAWLESS_PREFIX + str(level_index))
	if level_index >= 0 and level_index < SPEEDRUN_TARGET_SEC.size():
		if elapsed_sec <= SPEEDRUN_TARGET_SEC[level_index]:
			_unlock(SPEEDRUN_PREFIX + str(level_index))


func _unlock(id: String) -> void:
	if not DEFINITIONS.has(id):
		return
	if SaveManager.is_achievement_unlocked(id):
		return
	SaveManager.save_achievement_unlocked(id)
	achievement_unlocked.emit(id)


## One Dictionary per achievement in display order, merging the static
## definition with live unlock state, for achievements_screen.gd to render.
func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ORDER:
		var def: Dictionary = DEFINITIONS[id]
		result.append({
			"id": id,
			"title": def["title"],
			"description": def["description"],
			"unlocked": SaveManager.is_achievement_unlocked(id),
		})
	return result


func get_title(id: String) -> String:
	return DEFINITIONS.get(id, {}).get("title", id)
