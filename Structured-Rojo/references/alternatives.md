# Alternatives: modern swaps for the default stack

Load this when the user asks whether the default libraries are still the best choice, wants
a more modern setup, or is starting fresh and open to current options. The default stack
(Knit / Roact / Rodux / ProfileService / Aftman) is solid and matches the reference
framework, but the Roblox ecosystem has moved on in places. Here's how to swap pieces
*without* abandoning the structure this skill teaches.

The key idea: **the layout and the patterns are durable; the libraries are replaceable.**
Server feature modules, a two-phase lifecycle, a clear client boundary, a server-authoritative
data layer, a client store that mirrors server truth, all of that survives any library swap.

## Toolchain: Aftman → Rokit

Rokit is the in-house successor to Aftman and the recommended default for new projects. Same
job (pin tool versions per project), same `[tools]` table shape, actively maintained.
Migrating is mostly renaming `aftman.toml` to `rokit.toml` and re-adding tools. Foreman is
the older predecessor to both, only relevant in legacy repos.

## Service/Controller framework: Knit → modern options

Knit works and is widely understood, but its original author has moved toward other patterns.
Current alternatives:

- **Flamework** (typescript-first, for roblox-ts projects), decorator-based services/
  controllers with strong typing. Natural choice if the project is roblox-ts.
- **Lightweight DIY / loader patterns**, many studios now use a thin module-loader plus
  plain modules instead of a full framework, leaning on signals/atoms for communication.
- **Sleitnick's newer libraries**, the building blocks (Signal, Trove, Comm, etc.) are
  current even where the all-in-one framework isn't.

If you swap: keep the "one feature per module, init-then-start lifecycle, explicit client
boundary" shape. Map `Knit.CreateService` → the new framework's service primitive,
`Client` table → its remote/networking layer, `KnitInit/KnitStart` → its lifecycle hooks.

## UI: Roact → React-Lua / others

- **React-Lua** (Roblox's official React port) is the modern successor to Roact; the mental
  model is nearly identical and migration is well-trodden. In roblox-ts, this is `@rbxts/react`.
- **Fusion** and **Vide** are reactive UI libraries with a different (state-graph) model that
  many newer projects prefer for less boilerplate.

The data-flow rule is unchanged regardless: authoritative server → client store/state →
components render from state, never invent it.

## State: Rodux → modern state

- **Charm**, **Reflex**, and similar atom/producer libraries are popular modern replacements
  for Rodux, with less ceremony and good typing.
- Fusion/Vide fold state into the UI layer, so a separate store may not be needed.

Whatever you pick, the client store still *mirrors* server truth; it isn't the source.

## Data: ProfileService → ProfileStore

**ProfileStore** is the maintained successor to ProfileService from the same author. Same
guarantees (session locking, autosave, safe release), refreshed API. For new projects prefer
ProfileStore; the persistence rules in `data-persistence.md` apply identically, only some
method names change.

## Networking

If you outgrow Knit's `Client` table, dedicated networking libs (**Comm**, **ByteNet**,
**Warp**, etc.) give typed, batched, or buffer-optimized remotes. They slot in behind the
same boundary: client asks, server validates, server responds.

## roblox-ts (whole-project alternative)

If the team prefers TypeScript, **roblox-ts** compiles TS to Luau and pairs naturally with
Flamework + React-Lua + a modern state lib. The Rojo project layout and the
server/client/shared split are the same; the source language and some libraries change. This
skill's structure still applies.

## How to advise

Default to the established stack unless the user signals they want modern tooling or are
greenfield and language-flexible. When they do, recommend the successor with the smallest
conceptual gap (Rokit, ProfileStore, React-Lua) first, and only reach for a paradigm shift
(Fusion/Vide, roblox-ts) if they want it. Always preserve the structure, that's the part
this skill is really teaching.
