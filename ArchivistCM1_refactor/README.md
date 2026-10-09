# Archivist 4.4 — source project

This is the **multi-file development tree** for Archivist 4.4.

## Building

```sh
python3 tools/build.py
```

The generated runnable file is `dist/Archivist_4_4.lua`. Only the bundled file
should be executed. Do not execute files under `src/app/` individually: these
are ordered compilation fragments sharing Luau locals, to preserve behavior.

Source is separated into `src/ui/` (YSL components), `src/app/` (feature groups),
and `src/runtime/` (teleport launcher). Manifest order is explicit in
`tools/manifest.json`. The build uses only local Python stdlib; no network or
file I/O is added to the Lua runtime by the build system.

## State of the project

- Based on the TPHandler **StartupFix** build, not the older standalone YSL script.
- The existing performance changes for noclip caching, ESP cleanup, Fullbright
  conditional writes and throttled NPC selection are retained.
- Auto Kill now lazily creates its auxiliary target plate, and destroys it when
  disabled instead of allocating a permanent Workspace part at startup.
- The unused YSL ESP-preview module remains in the source tree but is **excluded**
  from the executable bundle, reducing startup parsing and teleport payload size.
- Dialogue and job sequences have not been rewritten during the refactor.
- Teleport queue operation depends on executor support.
- Full in-game integration and FPS tests are not included or claimed.

## Publishing & collaborators

Keep this repository private until the code is ready to disclose. In GitHub,
use **Settings → General → Danger Zone → Change visibility → Private**,
then **Settings → Collaborators and teams → Add people** to invite trusted
collaborators. The invitee needs to accept.

Do not commit tokens, executor credentials, user data, or private game files.
Third-party YSL UI components are bundled; review and preserve applicable
upstream notices/licences before any public distribution.
