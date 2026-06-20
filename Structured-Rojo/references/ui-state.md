# UI & State: Roact, Rodux, and the client boot

Load this when building UI, wiring client state, or working on the client startup sequence.
This is the client's `Roact/` (UI) + `Rodux/` (state) layers and how `init.client.luau`
brings them up.

## The two layers

- **Roact** is the UI library: you describe interface as a tree of components
  (`Roact.createElement`) and Roact reconciles it onto `PlayerGui`. Think React, for Roblox.
- **Rodux** is the state container: a single store holds client-side state (currency to
  display, open menus, settings), updated through actions and reducers. Think Redux.
- **RoactRodux / RoduxHooks** glue them together so components re-render when the slice of
  state they care about changes.

Why a store at all? Because lots of UI needs the same data (the HUD, the shop, the
inventory all show coins). A store gives one source of truth on the client and avoids
threading values through a dozen components. The *authoritative* values still live on the
server, the store mirrors what the server has told the client.

## Folder layout

```
client/
├── Roact/
│   ├── Root/
│   │   └── Application.luau     # top-level component tree (e.g. Root.Game)
│   ├── Components/              # reusable bits (Button, Tooltip, Frame)
│   └── Screens/                # full screens (HUD, Shop, Inventory, Settings)
├── Rodux/
│   ├── Store.luau              # creates the store from the root reducer
│   ├── Reducers/               # one reducer per slice of state
│   └── Actions/                # action creators
└── Modules/
    └── Synchronization.luau    # subscribes to services, dispatches into the store
```

## How data flows into the UI

The clean pattern, and the one the framework uses:

1. A **service** is the authority (e.g. `DataService` holds currency) and exposes a signal
   like `Money1Updated`.
2. A **controller** or a **synchronization module** on the client listens to that signal.
3. On each update it **dispatches an action** into the Rodux store.
4. Components connected to that slice **re-render** automatically.

So the chain is: server truth → Knit signal → client listener → Rodux dispatch → Roact
re-render. UI never invents numbers; it reflects what the server sent. This is also why
currency math stays server-side (golden rule): the client display is downstream of the
server, never the source.

## The client boot sequence

`init.client.luau` does more than the server bootstrap because the client has a load
experience. The framework's order (simplified):

1. Configure input/orientation basics.
2. Run a **preloader** that shows a loading screen and warms up controllers and assets.
3. When controllers are loaded, call `Knit.Start():await()` so all controllers init/start.
4. Require the Roact **root** component.
5. Run the **synchronization** module (subscribe services → store).
6. `Roact.mount` the app under `RoduxHooks.Provider` (so components can read the store) into
   `PlayerGui`.

```luau
Knit.Start():andThen(function()
    local Root = require(Client.Roact.Root.Application)
    require(Client.Modules.Synchronization)()   -- wire services → store

    Roact.mount(
        Roact.createElement(RoduxHooks.Provider, { store = Store }, {
            GameScreenGui = Roact.createElement(Root.Game),
        }),
        Players.LocalPlayer.PlayerGui,
        "UI"
    )
end):catch(warn):await()
```

Keep heavy work (image preloading, big component requires) inside the preloader phase so the
player sees a loading screen instead of a frozen frame. `src/ReplicatedFirst` is where the
earliest loading-screen script lives, because `ReplicatedFirst` runs before the rest of the
client.

## Practical tips

- **One reducer per concern.** A `currency` reducer, a `menus` reducer, a `settings`
  reducer, combined into the root. Easier to reason about and to test.
- **Components stay dumb.** They read state and fire callbacks; they don't talk to services
  directly. Let controllers/sync own the service wiring. This keeps UI reusable and testable.
- **Clean up connections** any controller makes to service signals (Trove/Janitor), same as
  anywhere else.
- **Mount once.** Mount the root app a single time at boot; don't mount per screen. Toggle
  screen visibility through state.

## Modern note

Roact + Rodux is the established stack and what the reference framework uses, but the
ecosystem has newer options (e.g. React-Lua / roblox-ts React, and signal/atom-based state
libraries). The data-flow idea, authoritative server, a client store that mirrors it,
components that render from state, transfers directly. See `references/alternatives.md`.
