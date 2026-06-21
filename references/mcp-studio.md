# Driving Roblox Studio live (MCP)

Load this before any live build, test, or debug loop inside Studio. If a Roblox Studio MCP
is connected to the session, you can do far more than hand over code, you can build it, run
it, read the console, and fix it in place. This reference is about using that responsibly
alongside the Rojo workflow.

## Detect what you have

First, check which Studio tools exist this session. Capability varies by server, so probe by
name rather than assuming. Common tools you may see:

- **Execute Luau**, `execute_luau` or `run_code`. The workhorse: run arbitrary Luau in
  Studio to create/inspect/modify instances or run logic.
- **Read console**, `get_console_output`. Errors and prints; the heart of the debug loop.
- **Inspect the tree**, `search_game_tree`, `inspect_instance`, `get_studio_state`.
- **Read/search scripts**, `script_read`, `script_search`, `script_grep`,
  and bulk edits via `multi_edit`.
- **Assets**, `insert_asset`, `search_asset`, and generators
  (`generate_mesh`, `generate_material`, `generate_procedural_model`).
- **Play testing**, `start_stop_play`, `wait_job_finished`, `screen_capture`.

If none of these are present, you're in **offline mode**: generate files and give precise
manual steps (install plugin, `rojo serve`, Connect, run). Everything still works; you just
verify by asking the user to run it.

## Rojo and the MCP are complementary, not rivals

Keep their roles straight or you'll fight yourself:

- **Rojo owns the source.** Files on disk → Studio. This is where persistent code lives and
  what gets committed. New scripts, services, controllers: write them as files.
- **The MCP is for live action on the running place**, running a snippet to check behavior,
  inspecting the current tree, reading the console after a change, inserting an asset,
  play-testing.

So the rhythm is: write/edit files (Rojo syncs them in) → use the MCP to run and observe →
read the console → adjust the files. Don't use `execute_luau` to author permanent game code
that should be a tracked file; that code wouldn't be in the repo. Use it to *test and
inspect*.

## The debug loop

This is the main reason to have the MCP. Tight, evidence-driven iteration:

1. **Reproduce.** Run the scenario (`start_stop_play`, or `execute_luau` to trigger the
   code path).
2. **Read the console** (`get_console_output`). Get the actual error and stack, not a guess.
3. **Locate** the offending code, `script_grep` / `script_search` to find it, `script_read`
   to read it, or `inspect_instance` / `search_game_tree` for a state problem.
4. **Form one hypothesis** about the cause. State it.
5. **Fix in the files** (so it's tracked), or for a quick probe, test the fix with
   `execute_luau` first, then write it to the file once confirmed.
6. **Re-run and re-read the console** to confirm. Don't assume; verify against output.
7. Repeat until the console is clean and behavior is right.

`workflows/debug-loop.md` walks this with the framework's conventions in mind.

## Verifying a build

After scaffolding or adding a feature, verify rather than declare success:

- Confirm the tree matches the intended structure (`search_game_tree`), services under
  `ServerScriptService.Server.Services`, controllers under the client path, packages present.
- Run `Knit.Start()` indirectly by play-testing and read the console for the
  `[SERVER] started` / Knit-client-started prints and any init errors.
- For a feature, trigger its client→server path and watch the console for the expected
  validation and the server→client signal landing.

## Safety and good manners

- **Read before you write.** Inspect current state before mutating it; don't blow away the
  user's work.
- **Prefer small, reversible steps.** Studio has undo; still, make changes you can explain.
- **Never run code you wouldn't show the user.** No obfuscated or surprising actions, the
  same principle of least surprise that applies to the skill itself.
- **Treat play-test output as truth.** If the console disagrees with your mental model, the
  console is right.

## Quick capability map

| You want to… | Reach for |
|---|---|
| Run/inspect logic live | `execute_luau` / `run_code` |
| See what broke | `get_console_output` |
| Find code | `script_grep`, `script_search`, then `script_read` |
| Understand current state | `search_game_tree`, `inspect_instance`, `get_studio_state` |
| Add an asset | `insert_asset`, `search_asset`, the `generate_*` tools |
| Play-test | `start_stop_play`, `wait_job_finished`, `screen_capture` |
| Bulk-edit scripts | `multi_edit` |

Names differ between MCP servers, adapt to whatever this session actually exposes.
