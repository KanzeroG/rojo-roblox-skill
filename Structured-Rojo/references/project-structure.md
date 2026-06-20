# Project Structure: where everything lives

Load this for layout questions: "where does this script go?", setting up `default.project.json`,
or refactoring a codebase that's grown messy. This is the canonical structure the whole
skill assumes.

## The mapping

`default.project.json` connects folders to Roblox services. The framework's mapping:

```json
{
  "name": "MyGame",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared":   { "$path": "src/shared" },
      "Packages": { "$path": "Packages" }
    },
    "ReplicatedFirst": {
      "$className": "ReplicatedFirst",
      "$path": "src/ReplicatedFirst"
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

| Filesystem | Becomes | Why there |
|---|---|---|
| `src/shared` | `ReplicatedStorage.Shared` | Both server and client can require it |
| `Packages` | `ReplicatedStorage.Packages` | Wally deps, shared realm, git-ignored |
| `src/server` | `ServerScriptService.Server` | Server-only; clients literally cannot see it |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` | Cloned into each player on join |
| `src/ReplicatedFirst` | `ReplicatedFirst` | Runs earliest on the client (loading screen) |

You can add more (`ServerStorage`, `StarterGui`, `Lighting` properties, `SoundService`
properties) as the game needs them. `templates/default.project.json` has a fuller example.

## Folder layout inside src

```
src/
├── server/
│   ├── init.server.luau      # bootstrap: require all Services, then Knit.Start()
│   ├── Services/             # one Knit service per feature
│   │   ├── DataService.luau
│   │   ├── ShopService.luau
│   │   └── InventoryService.luau
│   ├── Classes/              # server-side OOP classes (instances of game objects)
│   ├── Constants/            # server-only constant tables (e.g. data templates)
│   └── Modules/              # server-only libraries (e.g. ProfileService)
│
├── client/
│   ├── init.client.luau      # bootstrap: boot controllers, mount UI
│   ├── Controllers/          # one Knit controller per feature/area
│   ├── Roact/                # UI components and screens (see ui-state.md)
│   ├── Rodux/                # client state store (see ui-state.md)
│   └── Modules/              # client-only helpers
│
├── shared/
│   ├── Classes/              # classes both sides construct
│   ├── Configs/              # config for shared packages
│   ├── Data/                 # the game's config tables — see below
│   └── Helpers/              # small pure utilities (table, number, string helpers)
│
└── ReplicatedFirst/
    └── initLoadingScreen.client.luau
```

### `shared/Data` is the heart of a data-driven game

This is where the game's *content* lives as plain Luau tables, items, pets, currencies,
shops, codes, biomes, monetization products, etc. Both server and client read from the same
source of truth, which is exactly what you want: the server validates against it, the client
displays from it, and they never disagree.

```
shared/Data/
├── Items/            # item definitions
├── Monetization/     # gamepass / product ids and effects
├── Player/           # default player config
├── Codes.luau        # redeemable codes
├── Colors.luau       # palette
└── ...
```

When you add a feature, its *content* usually goes in `shared/Data`, its *server logic* in
`server/Services`, and its *client behavior + UI* in `client/Controllers` + `client/Roact`.
That three-part split is the spine of `workflows/add-feature.md`.

## File naming → Roblox class

Rojo reads the suffix to decide the instance class. This matters: a plain `.luau` in
`src/server` is a `ModuleScript` (won't run on its own), only `init.server.luau` or a
`*.server.luau` actually executes.

| File | Becomes | Runs? |
|---|---|---|
| `*.server.luau` | `Script` (server) | Yes, on server |
| `*.client.luau` | `LocalScript` | Yes, on client |
| `*.luau` (plain) | `ModuleScript` | Only when required |
| `Foo/init.luau` | folder → `ModuleScript` named `Foo` | When required |
| `Foo/init.server.luau` | folder → `Script` named `Foo` | Yes, on server |
| `Foo/init.client.luau` | folder → `LocalScript` named `Foo` | Yes, on client |
| `Foo/init.meta.json` | sets properties on the `Foo` folder/instance |, |
| `*.model.json` / `*.rbxmx` | a model instance |, |

> Prefer `.luau` over `.lua`. It's the modern standard and gives the Luau LSP better
> information. The reference framework has a mix for historical reasons; new files should be
> `.luau`.

### When to use a folder with `init.luau`

A single-file module is just `Thing.luau`. The moment a module needs helpers of its own,
promote it to a folder:

```
DataService/
├── init.luau          # the service itself
├── DataSchema.luau    # supporting module
└── Migrations.luau
```

`require(...DataService)` still resolves to the folder because of `init.luau`. This keeps a
feature's pieces together instead of scattering them.

## Placement decision guide

Ask these in order:

1. **Could a cheating client abuse it, or does it own real state/data?** → `src/server`.
2. **Is it purely visual / input / local-only?** → `src/client`.
3. **Do both sides need the same values or types?** → `src/shared` (usually `Data` for
   content, `Helpers` for logic, `Classes` for shared object types).
4. **Must it run before the game finishes loading?** → `src/ReplicatedFirst` (keep it tiny).

When server and client both need a *behavior* (not just data), put the shared logic in
`shared` and let each side call it, don't duplicate it.

## Anti-patterns to flag in review

- Everything in one giant `init.server.luau`. Split into services.
- Currency/inventory logic on the client. Move authority to the server.
- Config values hardcoded in multiple files. Centralize in `shared/Data`.
- Committing `Packages/` or `*.rbxl*` build artifacts. Git-ignore them (see
  `toolchain-wally.md`).
- A 1,500-line service. One feature per module; promote to an `init.luau` folder and split.
