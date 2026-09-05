---
description: Open Zed on the current working directory (or a path you name).
---

Open Zed for the user.

Run `zed .` from the current working directory, backgrounded — the CLI can hold
the terminal for as long as the window lives, so it must not run in the
foreground.

If the user named a path in $ARGUMENTS, open that instead of `.`.

On Windows under Git Bash, if the `zed` shim on PATH fails, fall back to
`~/AppData/Local/Programs/Zed/bin/zed`.

Confirm in one line that it launched. Do not summarize the repo or start any
other work — this command opens an editor, nothing more.
