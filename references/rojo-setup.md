# Rojo Setup: from nothing to syncing

Load this when someone is installing Rojo for the first time, setting up the toolchain, or
getting the Studio plugin to connect. The goal: code on the filesystem, live-syncing into
Roblox Studio.

## How Rojo works (the mental model)

Rojo has two halves that talk to each other:

- The **CLI** runs on your computer. It watches your project folder and serves changes.
- The **Studio plugin** runs inside Roblox Studio. It connects to the CLI and applies
  changes to the live game tree (the DataModel).

You edit files in VS Code → the CLI notices → the plugin updates Studio. That's the loop.
A `default.project.json` file tells Rojo how your folders map onto Roblox services.

## Step 1: Install the toolchain manager

Pinning tool versions per project is what keeps "works on my machine" from happening. Use a
toolchain manager so everyone (and CI) runs the same Rojo, Wally, etc.

**Rokit** is the current, in-house manager and the recommended default. **Aftman** is its
predecessor and still widely used (the reference framework this skill is based on used
Aftman), either is fine, Rokit is the forward-looking choice.

```bash
# Rokit (recommended) — install once, then per-project:
rokit init                       # creates rokit.toml in the project root
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit install                    # downloads the pinned tools

# Aftman (legacy alternative)
aftman init
aftman add rojo-rbx/rojo
aftman add UpliftGames/wally
```

A resulting `rokit.toml` looks like:

```toml
[tools]
rojo = "rojo-rbx/rojo@7.5.1"
wally = "UpliftGames/wally@0.3.2"
stylua = "JohnnyMorganz/StyLua@2.0.2"
selene = "Kampfkarren/selene@0.28.0"
```

> Version numbers age. Check the latest on each tool's GitHub releases page before pinning,
> or copy versions from an existing healthy project. Don't invent version numbers.

If someone doesn't want a toolchain manager at all, Rojo can also be installed via
`cargo install rojo` (needs Rust) or by downloading a binary from the Rojo GitHub releases.
The toolchain-manager route is still preferable for any real project.

## Step 2: Install the Roblox Studio plugin

The CLI alone can't touch Studio; you need the plugin. Three ways, pick one:

1. **Via the CLI (simplest, stays in sync with your CLI version):**
   ```bash
   rojo plugin install
   ```
   This installs/updates the matching plugin into your local Studio plugins folder. Restart
   Studio if it's open.

2. **From the Creator Marketplace inside Studio:** open the Toolbox / Plugins tab, search
   "Rojo", and install the official plugin by the Rojo team.

3. **From the VS Code Rojo extension** (`evaera.vscode-rojo`): it can install the plugin and
   start/stop the server with buttons, which is convenient if you live in VS Code.

After installing, you'll see a **Rojo** button in the Studio Plugins toolbar.

## Step 3: Create the project file

If you're starting fresh, scaffold it:

```bash
rojo init my-game        # creates a starter project + default.project.json
```

For this framework's layout, replace the generated `default.project.json` with the one in
`templates/default.project.json` and create the `src/server`, `src/client`, `src/shared`
folders. The full mapping and reasoning are in `references/project-structure.md`.

## Step 4: Serve and connect

```bash
rojo serve               # serves default.project.json on port 34872
```

Then in Studio: click the **Rojo** toolbar button → **Connect**. Once connected, the file
tree syncs into the DataModel live. Save a `.luau` file and watch it appear/update in Studio.

To produce a place file without a live session (e.g. for CI or a first-time build):

```bash
rojo build -o game.rbxlx   # open this in Studio, then serve on top of it
```

## Step 5: Editor setup (strongly recommended)

This is what makes the filesystem workflow actually pleasant. Full configs (VS Code
settings, extensions, format-on-save, sourcemap for type resolution) are in
`references/toolchain-wally.md`. At minimum install the **Luau LSP** and **Rojo** VS Code
extensions and enable sourcemap generation so autocomplete understands your tree.

## Common setup snags

- **Plugin won't connect:** make sure `rojo serve` is actually running, the port matches,
  and the plugin version isn't wildly older than the CLI. `rojo plugin install` realigns
  them.
- **"Class not found" / wrong instance types on sync:** usually a `default.project.json`
  mistake or a file suffix issue (`*.server.luau` vs `*.luau`). See
  `references/project-structure.md`.
- **Studio overwrote my files / files overwrote Studio:** two-way sync for non-script
  instances is limited. Treat the filesystem as the source of truth for code; author maps
  and level geometry in a committed base place file. More in `references/toolchain-wally.md`.
- **LSP shows red squiggles on `game`, `workspace`, etc.:** sourcemap isn't being generated
  or the Roblox types aren't enabled. See the editor section in `toolchain-wally.md`.

Once it's connected and syncing, move on to `references/project-structure.md` to lay the
project out, or `workflows/new-project.md` for the full from-scratch flow.
