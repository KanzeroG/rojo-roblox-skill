# Structured-Rojo

A Claude skill that teaches the model how a real, structured **Rojo** Roblox project is laid
out, so it can set one up, read it, extend it, and build games inside it without inventing
folder structures or losing track of where code belongs.

Most AI-generated Roblox code assumes the beginner setup: everything dumped into
`ServerScriptService`. That doesn't survive contact with a real project. This skill gives
Claude one exact, opinionated layout, filesystem-based, synced through Rojo, packaged with
Wally, organized into `server` / `client` / `shared` with a service-and-controller
architecture, and the conventions that hold it together.

It's focused on **Rojo and project structure**, with feature-building guidance layered on
top (how to add a feature *through* the framework). It is not a broad genre-by-genre
game-design encyclopedia.

## What's inside

```
Structured-Rojo/
├── SKILL.md                  # Router + cheat sheet + Studio-MCP detection
├── references/
│   ├── rojo-setup.md         # Install Rojo CLI, the Studio plugin, the toolchain
│   ├── toolchain-wally.md    # Wally, StyLua, Selene, sourcemap, editor, Git, CI
│   ├── project-structure.md  # The canonical layout + project.json mapping
│   ├── services-controllers.md # The Knit service/controller architecture + lifecycle
│   ├── ui-state.md           # Roact (UI) + Rodux (state) + client boot
│   ├── data-persistence.md   # Safe player data (ProfileService/ProfileStore)
│   ├── conventions.md        # Naming, headers, cleanup + sharp-edges table
│   ├── mcp-studio.md         # Driving Studio live (build / test / debug)
│   └── alternatives.md       # Modern swaps for each default library
├── templates/                # Copy-paste project.json, wally.toml, rokit.toml,
│                             #   service/controller/bootstrap files
└── workflows/                # new-project, add-feature, debug-loop, code-review
```

`OVERVIEW.md` (in this repo) is the project charter, the why and the scope.

## The framework it teaches

| Layer | Default | Notes |
|---|---|---|
| Sync | **Rojo** | Filesystem ⇄ Studio |
| Packages | **Wally** | `wally.toml` → `Packages/` |
| Toolchain | **Rokit** (Aftman compatible) | Pins tool versions |
| Architecture | **Knit** services + controllers | One feature per module, two-phase lifecycle |
| UI / State | **Roact** + **Rodux** | Client store mirrors server truth |
| Data | **ProfileService / ProfileStore** | Session-locked, no data loss |

The structure is the durable part; the libraries are the recommended default and are
swappable. `references/alternatives.md` covers modern replacements (Rokit, React-Lua,
ProfileStore, Flamework, roblox-ts, etc.).

## Install

Copy the `Structured-Rojo/` folder into your Claude skills directory (or install the packaged
`.skill` file). Once installed, Claude loads it automatically whenever a task involves Rojo,
a `default.project.json`, Wally, or a structured Roblox project, you don't have to invoke it
by name.

## Usage

Just describe the task in plain language, for example:

- "Set up a new Rojo project for my game."
- "Add a shop feature."
- "Where should this script go?"
- "Review this service for security issues."
- "My data isn't saving, help me debug it."

The skill routes each request to the right reference, template, or workflow. If a Roblox
Studio MCP is connected, it can build and verify live; otherwise it produces ready-to-use
files and clear manual steps.

## Credits

Independent, open-source skill by Faza. Its router-plus-library shape is inspired by existing
open-source Roblox skill work, and its conventions are modeled on patterns common in
production Rojo projects, rewritten here as an original work. Not affiliated with Roblox or
the Rojo project.
