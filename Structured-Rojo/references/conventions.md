# Conventions: naming, headers, cleanup, and the sharp edges

Load this when writing new code in the framework or reviewing existing code. These are the
small, consistent habits that make the codebase feel like one thing instead of ten people's
side projects, plus the bugs that bite hardest, so you can avoid them up front.

## Naming

- **Services / Controllers**: PascalCase, suffixed by role, `ShopService`, `ShopController`.
  The module filename and the `Name` field must match (that's how `Knit.GetService` finds it).
- **Modules / Classes**: PascalCase, `FishClass`, `FormatNumber`.
- **Config tables in `shared/Data`**: PascalCase files returning a table, `Pets.luau`,
  `Codes.luau`.
- **Local variables / functions**: camelCase. Private methods often prefixed with `_`
  (`self:_loadProfile`).
- **Constants**: `UPPER_SNAKE_CASE` for true constants.

## Logging

Give each module a `selfPrint` prefix so console output is greppable:

```luau
local selfPrint = "[ ShopService ]"
print(`{selfPrint} purchase granted to {player.Name}`)
```

Use Luau string interpolation (backticks) rather than `..` concatenation in new code.

## Module ordering

A consistent top-to-bottom shape makes any file scannable:

1. `game:GetService(...)` calls
2. Package requires (`Knit`, `Trove`, etc.)
3. Helper / sibling requires (siblings as `local X` to be filled in `KnitInit`)
4. `Knit.CreateService` / `CreateController` definition
5. `selfPrint`
6. Client methods, then server methods, then private methods
7. `KnitInit`, then `KnitStart`
8. `return TheModule`

## Cleanup: no leaks

Every connection and every spawned instance needs an owner that disposes it. Untracked
`:Connect()` calls are the classic Roblox memory leak, especially per-player ones that never
get disconnected when the player leaves.

```luau
local Trove = require(ReplicatedStorage.Packages.Trove)

local trove = Trove.new()
trove:Connect(part.Touched, onTouch)
trove:Add(Instance.new("Highlight"))
-- later, on cleanup (player leaving, object destroyed):
trove:Destroy()   -- disconnects + destroys everything it tracked
```

Janitor works the same way; pick one per project and stick with it. Per-player state should
be created in a `PlayerAdded` handler and fully torn down in `PlayerRemoving`.

## Types

Annotate public function signatures and module APIs. Use `--!strict` on critical modules
(data, economy). The Luau LSP + sourcemap make this pay off in autocomplete and early error
detection. Don't let it block you on fast-moving gameplay code, but data/money code should be
typed.

## Validation checklist for every `Client` method

Knit injects `player` as arg 1; everything after is attacker-controlled. Before acting:

1. **Type**, `typeof(x) == "string"` / `"number"` / etc. Reject otherwise.
2. **Range / sanity**, quantities positive, ids that actually exist in `shared/Data`,
   strings within length limits.
3. **Ownership**, does this player actually own the thing they're acting on?
4. **State**, is the action legal right now (alive, not already purchased, shop open)?
5. **Rate limit**, track last-call timestamps per player; drop floods.

Only after all five do you touch data. This single checklist prevents most economy exploits.

---

## Sharp edges (severity-rated)

These come up constantly. Keep them in mind on every task; the first three can wreck a live
game.

| ID | Severity | Trap | Fix |
|---|---|---|---|
| SE-1 | CRITICAL | Data loss / rollback from no session locking | Use ProfileService/ProfileStore, never raw `SetAsync` for player data. See `data-persistence.md`. |
| SE-2 | CRITICAL | Client-side currency/inventory math | All economy math server-side and validated. Client only displays. |
| SE-3 | CRITICAL | `ProcessReceipt` mishandling (double-charge / free items) | Grant + persist, THEN return `PurchaseGranted`; on failure return `NotProcessedYet`. |
| SE-4 | HIGH | Memory leaks from undisconnected events | Track every `:Connect()` in a Trove/Janitor; destroy on cleanup. |
| SE-5 | HIGH | RemoteEvent / Knit method flooding | Per-player rate limiting on `Client` methods. |
| SE-6 | HIGH | Calling a sibling service during `KnitInit` | Resolve in `KnitInit`, use in `KnitStart`. |
| SE-7 | MED | `WaitForChild` with no timeout hanging the client | Pass a timeout and handle nil, or rely on Rojo-synced structure that's guaranteed present. |
| SE-8 | MED | Trusting `mouse`/`Camera`/position from the client | Treat client-reported positions as hints; verify server-side for anything that matters. |
| SE-9 | MED | Putting shared content only on the server or only on the client | Content the client must display goes in `shared/Data`, not `server`. |
| SE-10 | LOW | `.lua` vs `.luau`, or wrong `*.server`/`*.client` suffix | Match the suffix to the intended Roblox class. See `project-structure.md`. |

When reviewing, walk the code against this table and the validation checklist, that's most
of what `workflows/code-review.md` does.
