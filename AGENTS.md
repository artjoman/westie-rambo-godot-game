# Agents

As explained in [README.md](README.md), this project's real purpose is practicing Godot development while working almost entirely through Claude Code as an autonomous dev partner. To make that concrete, the work is organized around four named roles, each backed by a real, invokable [Claude Code subagent](https://docs.claude.com/en/docs/claude-code/sub-agents) defined in `.claude/agents/`. Any of them can be dispatched directly via the `Agent` tool's `subagent_type` parameter (e.g. `subagent_type: "developer"`), or orchestrated together by `team-lead`.

## The roles

### `developer` — [.claude/agents/developer.md](.claude/agents/developer.md)
A professional game developer with 15 years across OpenGL, Unreal Engine, and Godot. Owns implementation: GDScript, scene wiring, physics/collision tuning, engine-level bug fixes. Reuses this project's existing components and conventions (shared `health_component`/`hurtbox`/`bullet_pool`, the checkpoint-revival pattern, the free-swimming-enemy convention) instead of reinventing them.

### `qa-tester` — [.claude/agents/qa-tester.md](.claude/agents/qa-tester.md)
A keen-eyed QA tester focused on finding real bugs and keeping the player experience smooth. Verifies gameplay changes using this project's proven methodology — fast closed-form checks and short bounded headless-Godot scenes over long live simulations — and never signs off on a "looks fine" without actually checking the relevant game state.

### `designer` — [.claude/agents/designer.md](.claude/agents/designer.md)
Creates and tunes sprites, sound effects, and music. Fluent in this project's from-scratch procedural pipeline (everything in the game so far is procedurally generated pixel art and synthesized audio, never imported), and also knows how to reach for external generative tools — Nanobanana (images), ElevenLabs (voice/audio), OpenAI (images/audio) — when procedural generation isn't enough, flagging missing API keys rather than assuming they're configured.

### `team-lead` — [.claude/agents/team-lead.md](.claude/agents/team-lead.md)
Orchestrates the other three toward one goal: the best possible game. Breaks requests into a plan, delegates implementation/assets/verification to the right agent, reconciles conflicting outputs, and only reports a feature "done" once QA has actually confirmed it.

## How they collaborate

The default flow for a non-trivial feature request is:

```
user request
     │
     ▼
 team-lead  ──(plans, tracks tasks)
     │
     ├──► developer   (implements the feature)
     ├──► designer    (produces any new sprites/audio it needs)
     └──► qa-tester   (verifies the assembled result end-to-end)
     │
     ▼
 team-lead reports back to the user, only after QA has signed off
```

For small, single-discipline asks (a pure code fix, a single new sprite, a quick verification pass), it's fine to invoke `developer`, `designer`, or `qa-tester` directly instead of going through `team-lead` — the orchestration layer exists for when a request actually spans multiple disciplines or needs a plan, not as mandatory overhead for everything.
