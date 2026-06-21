# Workflow: add a feature across all layers

Use this for "add a shop / inventory / daily reward / quest / …", anything that touches
server logic, client behavior, shared content, and usually UI. The whole point of the
framework is that features have a predictable shape; this is that shape as a checklist.

A feature is almost always three (sometimes four) parts:

1. **Content** → `src/shared/Data`
2. **Authority** → `src/server/Services`
3. **Client behavior** → `src/client/Controllers`
4. **UI** (if it has any) → `src/client/Roact` + `src/client/Rodux`

Work in that order, content first, then the server that validates against it, then the
client that requests and displays.

## Steps

1. **Define the content.** Add the feature's data as plain tables in `src/shared/Data`
   (e.g. `Data/Shop/Items.luau`). Both sides read this; it's the source of truth. Decide
   the shape now, ids, prices, effects, because the server validates against it.

2. **Create the service.** Copy `templates/service.luau` into `src/server/Services/` and
   rename it + its `Name` (e.g. `ShopService`). Then:
   - Add `Client` methods for what the client may request (client → server).
   - Add `Client` signals for what the server pushes back (server → client).
   - In each `Client` method, run the full validation checklist (type, range, ownership,
     state, rate-limit, see `references/conventions.md`) before touching state.
   - Route any data changes through `DataService` (server-owned, persisted). Resolve
     `DataService` in `KnitInit`, use it in `KnitStart`+.

3. **Create the controller.** Copy `templates/controller.luau` into
   `src/client/Controllers/` and rename it. Resolve the service in `KnitInit`; in
   `KnitStart`, connect to its signals and expose methods the UI can call. Track any
   connections in a Trove/Janitor.

4. **Wire the UI (if any).** Add a reducer/action for the feature's display state in
   `src/client/Rodux`, a screen/component in `src/client/Roact`, and have the controller
   (or the synchronization module) dispatch into the store when the server signals an
   update. Components render from state; they don't call the service directly. See
   `references/ui-state.md`.

5. **No registration step.** The bootstraps auto-require everything in `Services/` and
   `Controllers/`. Just create the files.

6. **Verify.** Play-test (or use the Studio MCP per `references/mcp-studio.md`): trigger the
   client → server path, confirm the server validates and the server → client signal lands,
   and check that data persists across a rejoin. Watch the console for the feature's prints
   and any errors.

## Security gut-check before calling it done

- Could a client send a bad/forged argument to any `Client` method and gain something?
  If yes, the validation isn't complete.
- Is any currency/inventory math happening on the client? Move it to the server.
- Does every per-player connection get cleaned up on leave?
- Is the content in `shared/Data` (so the client can display it) rather than stranded on the
  server?

## Done when

- The feature works end to end in a play-test with a clean console.
- Server is authoritative; client only requests and displays.
- Data changes persist (rejoin and confirm).
- Files sit in the right layers and follow the conventions.
