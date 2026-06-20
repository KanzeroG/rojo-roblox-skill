# Workflow: debug loop

Use this when something is broken: an error in the console, a feature not firing, data not
saving, UI not updating. The aim is tight, evidence-driven iteration instead of guess-and-
check. Strongest with a Studio MCP connected (`references/mcp-studio.md`); still works
offline by asking the user to run and paste output.

## The loop

1. **Reproduce it.** Get the bug to happen on demand, play-test, or run the exact code path
   (`execute_luau` / `run_code` if you have the MCP). A bug you can't reproduce, you can't
   confirm fixed.

2. **Read the real error.** `get_console_output` (or ask the user to copy the Output
   window). Get the actual message and stack trace. Don't theorize from the symptom; read
   what Roblox is telling you.

3. **Locate it.** Use the stack trace plus `script_grep` / `script_search` to find the code,
   `script_read` to read it in full. For a state problem (wrong value, missing instance),
   `inspect_instance` / `search_game_tree`.

4. **One hypothesis at a time.** State the suspected cause out loud before changing anything.
   Check it against the framework's known traps first, they're common:
   - Calling a sibling service during `KnitInit` (resolve there, use in `KnitStart`).
   - Client trusted for something the server should own.
   - A `Client` method missing validation, getting bad input.
   - An undisconnected per-player connection firing after the player left.
   - Wrong file suffix → wrong instance class → script never ran.
   - Raw `SetAsync` / no session lock behind a data bug.

5. **Fix in the files.** Edit the source (so the fix is tracked and synced via Rojo). For a
   risky guess, probe it live with `execute_luau` first, then commit it to the file once
   confirmed, don't leave logic living only in a live snippet.

6. **Re-run and re-read.** Reproduce again and read the console. Confirm against output, not
   vibes. If it's not fixed, you learned something, back to step 4 with a new hypothesis.

7. **Stop when** the console is clean and the behavior is correct across a normal play-test
   (and a rejoin, if data was involved).

## Anti-patterns while debugging

- Changing several things at once, you won't know which fixed it (or broke something else).
- "Fixing" by adding `task.wait()` until it works, that's hiding a lifecycle/ordering bug;
  find the real cause (often a `KnitInit`/`KnitStart` mistake).
- Editing live in Studio and forgetting to write it to the file, the fix vanishes next sync.
- Declaring victory without re-reading the console.
