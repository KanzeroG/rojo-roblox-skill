# Workflow: start a new project from zero

Use this when someone wants a fresh, structured Rojo game set up correctly. The end state:
a syncing project with the canonical layout, a running bootstrap, and the toolchain in place.

Pair with `references/rojo-setup.md` (install details) and `references/project-structure.md`
(layout reasoning). Confirm the user has Roblox Studio installed before starting.

## Steps

1. **Toolchain.** Initialize Rokit and add the tools, then install:
   ```bash
   rokit init && rokit add rojo-rbx/rojo && rokit add UpliftGames/wally && rokit install
   ```
   (Aftman is the legacy alternative, same idea.) Copy `templates/rokit.toml` and adjust
   versions to current releases.

2. **Studio plugin.** `rojo plugin install`, or install "Rojo" from the Studio marketplace.
   This is what lets the CLI talk to Studio.

3. **Project file + folders.** Drop `templates/default.project.json` at the root and create:
   ```
   src/server/Services/      src/server/Classes/   src/server/Constants/  src/server/Modules/
   src/client/Controllers/   src/client/Roact/      src/client/Rodux/      src/client/Modules/
   src/shared/Data/          src/shared/Helpers/    src/shared/Classes/    src/shared/Configs/
   src/ReplicatedFirst/
   Packages/   (git-ignored; populated by wally install)
   ```

4. **Packages.** Copy `templates/wally.toml`, set the `name`, then `wally install`.
   Regenerate the sourcemap so the LSP resolves types:
   ```bash
   rojo sourcemap default.project.json -o sourcemap.json
   ```

5. **Bootstraps.** Copy `templates/init.server.luau` → `src/server/init.server.luau` and
   `templates/init.client.luau` → `src/client/init.client.luau`.

6. **A first service + controller (smoke test).** Copy `templates/service.luau` →
   `src/server/Services/TemplateService.luau` and `templates/controller.luau` →
   `src/client/Controllers/TemplateController.luau`. They already print on start.

7. **Tooling configs + git.** Add `stylua.toml`, `selene.toml`, `.gitignore`, and
   `.vscode/` settings from `references/toolchain-wally.md`. Then `git init` and a first
   commit. Make sure `Packages/` and `*.rbxl*` are ignored.

8. **Serve + connect + verify.**
   ```bash
   rojo serve
   ```
   In Studio: Rojo toolbar → Connect. Play-test and confirm the console shows
   `[SERVER] started successfully` and `[CLIENT] Knit started`. If a Studio MCP is connected,
   verify directly per `references/mcp-studio.md` (check the tree, read the console).

## Done when

- The project syncs into Studio and play-testing prints both start messages with no errors.
- The folder layout matches `references/project-structure.md`.
- `Packages/` and build artifacts are git-ignored; configs and `wally.lock` are committed.

From here, build features with `workflows/add-feature.md`.
