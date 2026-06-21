# Workflow: code review against the framework

Use this to review Roblox/Luau code for structure, security, and convention fit, whether
it's a PR, a file the user pastes, or a whole project audit. Lead with the things that can
hurt a live game, then structure, then polish.

Pair with `references/conventions.md` (the sharp-edges table and validation checklist).

## Pass 1: security and data (the stuff that wrecks live games)

Walk the code against the CRITICAL/HIGH sharp edges first:

- **Client trust.** Does any `Client` method or RemoteEvent act on player-supplied data
  without validating type, range, ownership, state, and rate limit? Flag each one.
- **Economy authority.** Is currency/inventory math anywhere on the client? It must be
  server-side. The client display being wrong is a bug; the client *deciding* the balance is
  an exploit.
- **Data persistence.** Raw `SetAsync` on player data, or any save path without session
  locking (ProfileService/ProfileStore)? That's a data-loss/dupe risk, flag it hard.
- **Receipts.** If they sell products, is `ProcessReceipt` granting + persisting *before*
  returning `PurchaseGranted`, and returning `NotProcessedYet` on failure?

## Pass 2: structure

- **Placement.** Is each file in the right layer (server / client / shared)? Server logic
  leaking to the client, or shared content stranded server-side?
- **One feature per module.** Any service/controller doing two jobs, or a file past ~300
  lines that should be split (promote to an `init.luau` folder)?
- **Lifecycle.** Siblings resolved in `KnitInit` and used in `KnitStart`, not called during
  init? `Name` fields matching filenames?
- **Communication.** Server→client via signals, client→server via `Client` methods, with the
  server as the boundary. No ad-hoc remotes bypassing the pattern.

## Pass 3: cleanup and correctness

- **Leaks.** Every `:Connect()` and spawned instance tracked in a Trove/Janitor and disposed
  on cleanup? Per-player state torn down on `PlayerRemoving`?
- **`WaitForChild`** with sensible timeouts / nil handling.
- **pcall** around DataStore and other network calls.

## Pass 4: conventions and polish

- `selfPrint` prefix, module ordering, naming (PascalCase modules, camelCase locals).
- `.luau` not `.lua`; correct `*.server` / `*.client` suffixes.
- Types on public APIs and data/economy modules; `--!strict` where it counts.
- Formatting/lint clean (StyLua, Selene).

## Output format

Group findings by severity so the author fixes the dangerous things first:

```
CRITICAL  — data loss / exploit risk (fix before merge)
HIGH      — leaks, missing validation, lifecycle bugs
MEDIUM    — structure / placement issues
LOW       — naming, formatting, style
```

For each: where it is, why it matters (the consequence, not just "convention says so"), and
the concrete fix. Lead with what would hurt players in production.
