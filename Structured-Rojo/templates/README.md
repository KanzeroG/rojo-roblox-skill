# Templates

Copy-paste starting points so structure is never reinvented. Drop these into a real project
and rename the placeholders.

| File | Goes to | Purpose |
|---|---|---|
| `default.project.json` | project root | Rojo mapping (filesystem → DataModel) |
| `rokit.toml` | project root | Pinned toolchain (Rojo, Wally, StyLua, Selene) |
| `wally.toml` | project root | Package dependencies |
| `init.server.luau` | `src/server/` | Server bootstrap (auto-requires Services, starts Knit) |
| `init.client.luau` | `src/client/` | Client bootstrap (auto-requires Controllers, mounts UI) |
| `service.luau` | `src/server/Services/` | A blank Knit service following all conventions |
| `controller.luau` | `src/client/Controllers/` | A blank Knit controller |

When you copy a service or controller, rename **both** the filename and the `Name` field,
they must match for `Knit.GetService` / `Knit.GetController` to resolve it.

Version numbers in `rokit.toml` and `wally.toml` are examples. Check the tool's GitHub
releases / the Wally registry for current versions before committing; don't invent them.

See `../references/project-structure.md` for the full folder layout and
`../references/services-controllers.md` for how these pieces fit together.
