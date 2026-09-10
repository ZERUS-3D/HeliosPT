# Sharing logs & builds with the developer / AI assistant

This project is debugged through `latest.log` round-trips. Because the chat
environment can only open **public web URLs**, the most reliable workflow is
to push logs to this public GitHub repository.

---

## Option A (recommended): commit logs into `logs/`

1. Reproduce the problem after a **full game restart** (not "Reload Shaders").
2. Copy `.minecraft/logs/latest.log` immediately — it is overwritten on every
   launch.
3. Rename it using this convention:

   ```
   logs/YYYY-MM-DD_HHMM_<version>_<short-description>.log
   ```

   Examples:

   ```
   logs/2026-09-10_2030_v0.4_black-screen.log
   logs/2026-09-11_1802_v0.4_debug1-empty-voxels.log
   logs/2026-09-12_2145_v0.5_noise-not-denoised.log
   ```

4. Add a matching `.txt` note (optional but helpful): same base name, e.g.
   `logs/2026-09-11_1802_v0.4_debug1-empty-voxels.txt` describing preset,
   dimension, time of day, what you did, and what you expected vs. got.
5. Commit and push.
6. Send the **raw URL**, which looks like:

   ```
   https://raw.githubusercontent.com/<user>/<repo>/main/logs/2026-09-11_1802_v0.4_debug1-empty-voxels.log
   ```

   The repository must be **public** for the raw URL to be readable.

## Option B: GitHub Issues

Open an issue with the **Bug report** template and drag `latest.log` and
screenshots into the editor. Note: attached files on issues may not be
directly downloadable by automated assistants — when in doubt, use Option A
or paste the relevant log lines into the issue body.

## Option C: GitHub Gist

Create a secret/public gist with the log contents and send the raw URL
(`.../raw`).

---

## What to capture every time

- [ ] Full game restart before reproducing
- [ ] `latest.log` copied right after closing the game
- [ ] Pack version (v0.4 / commit hash) and profile (LOW / MEDIUM / HIGH)
- [ ] Dimension (Overworld / Nether / End) and in-game time
- [ ] `DEBUG_MODE` value, if changed
- [ ] Screenshots (F2 → `.minecraft/screenshots/`):
      - debug view 1 (voxels)
      - debug view 2 (GI buffer)
      - normal view (debug 0)
- [ ] Mod versions if they changed (Forge / Oculus / Embeddium)

## Which lines matter

Search the log for these markers and include everything around them:

```
Creating pipeline for dimension
Couldn't compile
error C
Failed to create shader rendering pipeline
disabling shaders
ClosedFileSystemException
[Oculus]
```

When unsure, attach the **whole** `latest.log` — it is cheap to read.

## Also commit the current build

When a log is from a modified/experimental build, commit the matching
`shaders/` state as well, or note the commit hash in the log's `.txt` note.
This makes every log reproducible against exact source.
