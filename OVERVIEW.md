# Structured-Rojo: Project Overview

> A Claude Skill that teaches the model how a real, structured Rojo project is laid out, so it can read, extend, and build Roblox games inside that framework without guessing.

This document explains what the skill is, who it's for, why it exists, and how it's put together. It's the charter that settles scope *before* the skill itself gets written.

---

## The problem this solves

When you ask an AI to write Roblox code, it usually defaults to the "everything dumped in `ServerScriptService`" style you'd see in a beginner tutorial. That's fine for a single script and useless the moment you have a real project. The moment a project uses **Rojo**, managing the game from the filesystem, syncing into Studio, with code split across `src/server`, `src/client`, and `src/shared`, most models lose the plot. They invent folder layouts that don't exist, put server logic on the client, forget how packages are required, or hand-write systems that the framework already provides.

The result is code that looks plausible but doesn't drop into your project. You spend more time fixing structure than you saved.

**This skill fixes the structure problem.** It gives the model an exact mental model of one specific, opinionated, production-style Rojo framework, so the code it writes lands in the right file, requires the right modules, and follows the conventions the rest of the codebase already uses.

---

## What it is

`Structured-Rojo` is an open-source [Claude Skill](https://docs.claude.com), a folder of Markdown that Claude loads on demand. It is **not** a library you install into your game and it is **not** a CLI tool. It's knowledge, packaged so the model can use it.

It is deliberately **scoped to Rojo and one structured framework**. It is not trying to be an encyclopedia of all Roblox development. Where a broad "make any Roblox game" skill would cover every genre, monetization model, and edge case, this one stays focused: *how is a Rojo project structured, and how do you build a game correctly inside that structure.* Game-building guidance is included, but always through the lens of the framework rather than as standalone tutorials.

### What's in scope

- Rojo project setup, `default.project.json`, the filesystem-to-DataModel mapping, `rojo serve` / `rojo build`.
- Toolchain, Aftman (or Rokit) for tool versions, Wally for package management.
- The structured framework, how `src/server`, `src/client`, and `src/shared` are organized, and the conventions inside each.
- The service/controller architecture, how server Services and client Controllers are defined, registered, and started.
- UI and state layers, how the UI and client state are organized and wired in.
- Data persistence, how player data is stored and loaded safely.
- Building a game *within* the framework, adding a feature end-to-end (server service + client controller + shared data + UI) the way the framework expects.
- Live build/test via the Roblox Studio MCP, when it's connected.

### What's out of scope (on purpose)

- Genre-by-genre game design playbooks (that's what the broader `roblox-game` skill is for).
- Deep dives on topics unrelated to project structure (marketing, art pipelines, etc.).
- Teaching Luau from zero, it assumes you can write Luau and focuses on *where the code goes and how it connects.*

---

## Who it's for

- **Teams with an existing Rojo project**, so Claude produces code that fits the codebase on the first try.
- **The wider community**, since it's open source. Anyone using a Knit-style Rojo setup can install it and get the same benefit.
- **Both beginners and experienced devs**, a beginner gets a correct project skeleton and clear conventions; an experienced dev gets an assistant that already knows the layout and stops fighting them on structure.

---

## The framework it teaches

The skill is built around the structure of a real production game project (used here only as a reference, the skill is rewritten as an independent work, not copied). That reference establishes a clear, repeatable shape:

**Tooling**

- **Rojo 7.x**, filesystem ⇄ Studio sync, the backbone of the whole setup.
- **Wally**, package manager; dependencies live in `wally.toml` and resolve into a `Packages/` folder.
- **Aftman / Rokit**, pins tool versions (Rojo, Wally) so everyone on the project uses the same ones.

**Project mapping** (`default.project.json`)

| Filesystem | Roblox DataModel location |
|---|---|
| `src/shared` | `ReplicatedStorage.Shared` |
| `Packages` | `ReplicatedStorage.Packages` |
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/ReplicatedFirst` | `ReplicatedFirst` |

**Architecture**, a service/controller pattern (the reference uses **Knit**):

- **Server** (`src/server`): `Services/` (each service is one feature, data, shop, inventory, combat…), plus `Classes/`, `Constants/`, and `Modules/`. A boot script requires every service in the folder, then starts the framework.
- **Client** (`src/client`): `Controllers/` (the client-side counterparts), a UI layer, a client state layer, and a boot/preload sequence.
- **Shared** (`src/shared`): `Classes/`, `Configs/`, `Data/` (config tables, items, currencies, etc.), and `Helpers/` (small reusable utilities).

**Supporting layers**

- A reactive **UI** layer and a client **state** layer.
- A safe **data persistence** layer for player profiles.
- Cleanup utilities (Trove/Janitor-style) so connections and instances don't leak.

### On the stack: default, but not dogma

The skill treats this stack (Knit + a Roact/Rodux-style UI/state pair + a ProfileService-style data layer + Wally) as the **recommended default**, because it matches the reference project and produces consistent output. But it will also note where the ecosystem has moved on, Knit is a mature, somewhat older pattern, and there are newer approaches to services, UI, and state, so the skill ages well and doesn't lock anyone into one choice. The *structure* (Rojo layout, server/client/shared split, one-feature-per-module) is the durable part; the specific libraries are swappable.

---

## How it's built (skill architecture)

The skill borrows its *shape* from a proven open-source skill: a **router plus a lazy-loaded library**. The entry file stays small and fast; deep knowledge lives in separate files that only load when relevant.

```
Structured-Rojo/
├── SKILL.md            # Router: intent → which files to load. Plus a quick-reference cheat sheet.
├── references/         # Deep-dive docs, loaded on demand
│   ├── rojo-setup.md            # project.json, serve/build, sourcemap
│   ├── toolchain-wally.md       # Aftman/Rokit + Wally packages
│   ├── project-structure.md     # the server/client/shared layout in full
│   ├── services-controllers.md  # the service/controller pattern + lifecycle
│   ├── ui-state.md              # UI + client state layers
│   ├── data-persistence.md      # safe player data
│   ├── conventions.md           # naming, headers, module style, cleanup
│   ├── mcp-studio.md            # live build/test via the Studio MCP
│   └── alternatives.md          # modern swaps for each default library
├── templates/          # Copy-paste-ready starting points
│   ├── new-project/             # a minimal correct Rojo skeleton
│   ├── service.luau             # a blank Knit-style service
│   ├── controller.luau          # a blank controller
│   └── feature-vertical-slice/  # service + controller + data + UI for one feature
└── workflows/          # Step-by-step guided flows
    ├── new-project.md           # spin up a fresh Rojo project from zero
    ├── add-feature.md           # add one feature across all layers, correctly
    ├── debug-loop.md            # iterate with the Studio MCP
    └── code-review.md           # check code against the framework's conventions
```

> These are the final file names; the built skill in `Structured-Rojo/` matches this layout.

### Roblox Studio MCP integration

The skill detects whether a Roblox Studio MCP is connected and adapts:

- **Connected** → it can run Luau live, read the console, insert assets, and play-test, so it can build *and verify* inside Studio instead of just handing you code.
- **Not connected** → it falls back to producing copy-paste-ready code and clear manual steps.

This mirrors the multi-mode approach from the reference skill, kept lean for this project's narrower scope.

### Voice

All prose is written in a natural, human voice (a humanizer pass over the drafts) rather than the usual AI cadence, but never at the expense of precision. The technical parts (folder paths, mappings, lifecycle order) are stated exactly, because the entire point is to stop the model from hallucinating structure.

---

## Why this won't make things up

The anti-hallucination strategy is concrete:

1. **One canonical layout, stated exactly**, the model gets a single, unambiguous mapping of file → DataModel location, not a vague description.
2. **Real templates over freehand code**, for the common cases the model copies a known-good template and fills it in, rather than inventing structure each time.
3. **Conventions written down**, naming, module headers, require patterns, and cleanup rules are explicit, so generated code matches existing code.
4. **MCP verification when available**, when Studio is connected, the model can actually run and check its work instead of asserting it's correct.

---

## Licensing & distribution

- Published as an open-source repo for anyone to use.
- Released into the public domain via a no-copyright `LICENSE` (do-whatever, no rights reserved).
- README with install/usage instructions, and clear attribution noting it's inspired by existing open-source work but written as an independent skill.

---

## Decisions settled

1. **Skill name**: `Structured-Rojo`.
2. **Toolchain**: default to **Rokit** (the modern successor); Aftman documented as the legacy alternative the reference project used.
3. **Stack**: the Knit / Roact / Rodux / ProfileService stack is the recommended default, with modern alternatives documented in `references/alternatives.md`.
4. **Studio MCP**: included, with live build/test guidance plus an offline fallback.
5. **License**: public domain, no copyright (a `LICENSE` file that waives all rights).

---

## Status

Built. The skill lives in `Structured-Rojo/`: `SKILL.md` (router + cheat sheet), nine reference docs, copy-paste templates, and four workflows. Prose was run through a humanizer pass for a natural voice while keeping the structure technically exact. See `README.md` for install and usage.
