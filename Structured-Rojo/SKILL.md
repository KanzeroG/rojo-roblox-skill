---
name: structured-rojo
description: >
  Build and maintain Roblox games as structured, filesystem-based Rojo projects.
  Use this whenever the work touches Rojo, a default.project.json, Wally packages, a
  rokit.toml/aftman.toml toolchain, or a Roblox project split into src/server, src/client,
  and src/shared. Trigger it for setting up Rojo from scratch (CLI + Studio plugin),
  laying out a project, writing or wiring Knit-style services and controllers, adding a
  feature across server/client/shared, organizing UI and state, persisting player data
  safely, or reviewing Roblox code for structure. Reach for this skill even when the user
  only says "Roblox game", "Luau project", "sync to Studio", or "where should this script
  go", if the answer involves project structure, this skill applies. Not just for the
  word "Rojo": any time Roblox code needs to live in real files with a sane architecture.
---

# Structured Rojo

A companion for building Roblox games the way professional studios do: code lives in real
files, syncs into Studio through **Rojo**, packages come from **Wally**, and the game is
organized into a predictable server / client / shared layout with a service-and-controller
architecture on top.

The whole point of this skill is to stop guessing about structure. Roblox tutorials drop
everything into `ServerScriptService` and call it a day. That falls apart fast. This skill
gives you one exact, opinionated layout and the conventions that go with it, so every file
you write lands in the right place, requires the right modules, and matches the rest of the
codebase.

The structure is the durable part. The specific libraries (Knit, Roact, Rodux,
ProfileService) are the recommended default, solid and battle-tested, but they are
swappable, and `references/alternatives.md` covers modern replacements when someone wants
them.

---

## First: detect your Studio connection

Before doing live work in Studio, figure out what you can actually do. There may be a
Roblox Studio MCP connected to this session, and how much you can automate depends on it.

1. **Live mode**, Studio MCP tools are present (look for tools like `execute_luau` /
   `run_code`, `get_console_output`, `insert_asset`, `start_stop_play`,
   `search_game_tree`). You can run Luau inside Studio, read the console, insert assets,
   and play-test. Use this to *build and verify*, not just to hand over code.
2. **Offline mode**, no Studio tools. Produce copy-paste-ready files and clear manual
   steps (install the plugin, run `rojo serve`, click Connect). Everything in this skill
   works offline; you just lose live verification.

Full guidance on driving Studio is in `references/mcp-studio.md`. Read it before any live
build or debug loop.

---

## Routing table

Match what the user wants, then load the listed files. Don't load everything up front,
pull in a reference only when the task calls for it.

| User intent | Load |
|---|---|
| Set up Rojo from zero (CLI, Studio plugin, toolchain) | `references/rojo-setup.md` + `workflows/new-project.md` |
| Add packages / Wally / linting / formatting / sourcemap | `references/toolchain-wally.md` |
| "Where does this go?" / project layout / refactor structure | `references/project-structure.md` |
| Write or wire a service (server) or controller (client) | `references/services-controllers.md` + `templates/service.luau` / `templates/controller.luau` |
| Build a whole feature (server + client + shared + UI) | `workflows/add-feature.md` + `references/services-controllers.md` |
| UI / state / Roact / Rodux / loading screen | `references/ui-state.md` |
| Save / load player data | `references/data-persistence.md` |
| Naming, headers, cleanup, common mistakes | `references/conventions.md` |
| Live build / run / debug in Studio | `references/mcp-studio.md` + `workflows/debug-loop.md` |
| Review code against the framework | `workflows/code-review.md` + `references/conventions.md` |
| "Is Knit/Roact/etc. still the best choice?" | `references/alternatives.md` |
| Start a brand-new game | `workflows/new-project.md` (then `add-feature.md` per system) |

If the intent is ambiguous, ask one short clarifying question, then route.

---

## The layout in one screen

This is the canonical mapping. Filesystem on the left, where it lands in the Roblox
DataModel on the right. Defined in `default.project.json`.

| Filesystem | Roblox DataModel | Holds |
|---|---|---|
| `src/server` | `ServerScriptService.Server` | Server `Services/`, `Classes/`, `Constants/`, server `Modules/`, `init.server.luau` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` | Client `Controllers/`, `Roact/` (UI), `Rodux/` (state), `init.client.luau` |
| `src/shared` | `ReplicatedStorage.Shared` | `Classes/`, `Configs/`, `Data/` (config tables), `Helpers/` |
| `Packages` | `ReplicatedStorage.Packages` | Wally-installed dependencies (git-ignored) |
| `src/ReplicatedFirst` | `ReplicatedFirst` | Loading screen, earliest client boot |

Rule of thumb for placement:

- **Authoritative logic, data, anti-cheat** → `src/server`. Clients can't see it.
- **Input, camera, UI, local effects** → `src/client`.
- **Anything both sides need** (config tables, types, shared classes, helpers) →
  `src/shared`.
- If a client could lie about it and it matters, the truth lives on the **server**.

File suffixes decide the Roblox class: `*.server.luau` → `Script`, `*.client.luau` →
`LocalScript`, plain `*.luau` → `ModuleScript`. A folder with `init.luau` becomes a
`ModuleScript`. Details in `references/project-structure.md`.

---

## Architecture in a nutshell

The default architecture is **Knit**: one feature per module, started by a small bootstrap.

- **Server** = a folder of **Services**. Each service is `Knit.CreateService({ Name, Client = {…} })`,
  owns one feature (data, shop, inventory, combat…), and exposes server-to-client
  communication through `Client` signals/functions. `init.server.luau` requires every
  service in the folder, then calls `Knit.Start()`.
- **Client** = a folder of **Controllers**, the client-side counterparts
  (`Knit.CreateController({ Name })`). They handle input, talk to services, and drive the
  UI. `init.client.luau` boots them, then mounts the UI.
- **Lifecycle**: `KnitInit` runs first on every module (grab references to other
  services/controllers here, never call them yet), then `KnitStart` runs (now everything
  exists, safe to use). Respect this order or you'll hit nil references.

Copy `templates/service.luau` and `templates/controller.luau` rather than writing these
from memory, they already follow the convention. Deep dive in
`references/services-controllers.md`.

---

## Golden rules

These hold on every task, so keep them in mind even without loading a reference.

> **Never trust the client.** Every RemoteEvent / Knit client request is attacker-controlled.
> Validate type, range, ownership, and cooldown on the server. Currency and inventory math
> is server-only; the client only displays.

> **One feature per module.** A service or controller does one thing. If a file passes
> ~300 lines or grows a second responsibility, split it. A folder with `init.luau` keeps
> related files together.

> **Respect the lifecycle.** Resolve other services in `KnitInit`, use them in `KnitStart`.
> Never assume a sibling is ready during your own init.

> **Clean up what you connect.** Every `:Connect()` and spawned instance needs an owner.
> Use Trove/Janitor so connections and parts don't leak, especially per-player ones.

> **Player data is sacred.** Never raw `SetAsync` player data. Use a session-locking layer
> (ProfileService/ProfileStore). See `references/data-persistence.md`.

---

## Quick reference

**Spin up / sync**

```bash
rojo serve            # start live sync (default port 34872), then Connect in Studio
rojo build -o game.rbxlx   # build a place file from the project
rojo sourcemap default.project.json -o sourcemap.json  # for Luau LSP + Wally types
wally install         # install dependencies into Packages/
```

**Server → client (Knit)**

```luau
-- service: declare a signal under Client
Client = { Notify = Knit.CreateSignal() }
-- fire it to one player
self.Client.Notify:Fire(player, payload)

-- controller: get the service and listen
local Svc = Knit.GetService("ThatService")
Svc.Notify:Connect(function(payload) ... end)
```

**Client → server (Knit)**, expose a method on `Client`, call it from the controller; the
server receives `player` as the first argument and must validate everything after it.

When in doubt about placement, communication, or lifecycle, load the matching reference
from the routing table rather than guessing.
