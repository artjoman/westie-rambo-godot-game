# Rambo Westie

A 2D run-and-gun game built in [Godot 4.7](https://godotengine.org/) (GDScript), in the style of classic side-scrolling shooters like Contra.

## Story

Rambo is a West Highland Terrier (a "westie") who talks like an '80s action hero and looks like one too — bandana included. His neighborhood has been overrun by a clan of sneaky **ninja cats**, and it's up to Rambo to fight through 5 levels of grass, swamp, gauntlet platforming, a vertical cliff climb, and a fully underwater reef to take them down.

## Features

- Multi-directional run-and-gun shooting with weapon pickups (machine gun, laser, and more)
- 5 hand-built levels, each with its own terrain, enemies, and boss fight
- A varied enemy roster: grunt/scout/brute/sniper cats, dive-bombing bats, pooping crows, swimming piranhas and sharks
- 3 boss fights (chaser, wall, splitter) reused/reskinned across levels
- Perks: jetpack, shield, flashbang
- Checkpoints with enemy revival (dead enemies past the last checkpoint respawn with you)
- Swimmable water zones with their own physics (levels 3 and 5)
- Dynamic music, procedural pixel-art sprites, and procedurally synthesized SFX
- Playable as a desktop build or exported to Android (APK in `builds/android/`)

## Why this project exists

This is a personal practice project with one real goal: **get hands-on with Godot game development while working almost entirely through Claude Code**, using it as an autonomous(-ish) development partner — planning features, writing GDScript, generating placeholder art/audio procedurally, wiring up scenes, and verifying changes — rather than hand-authoring everything in the editor. The "game" itself is a vehicle for that; the interesting part is seeing how far an AI-assisted, mostly-autonomous workflow can take a real Godot project from an empty folder to a playable, exportable game.

## Running it

Open the project folder in Godot 4.7+ and run it, or run headlessly:

```
godot --path . 
```

## Project layout

- `scenes/levels/` — the 5 playable levels (`level_01`–`level_05`) and shared level plumbing (`level_base.gd`)
- `scenes/player/`, `scenes/enemies/`, `scenes/bosses/` — player controller, enemy types, boss fights
- `scenes/weapons/`, `scenes/pickups/`, `scenes/hazards/` — bullets, weapon/perk pickups, checkpoints, water zones, boss triggers
- `scenes/ui/` — menus, HUD, win/game-over screens
- `autoload/` — global singletons (game state, save data, scene/level progression, audio/music)
- `assets/sprites/generated/`, `assets/audio/` — procedurally generated pixel art and SFX
- `builds/android/` — exported Android APK
