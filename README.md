# logs/

Commit Minecraft `latest.log` snapshots here for remote debugging.

## Naming convention

```
YYYY-MM-DD_HHMM_<version>_<short-description>.log
```

Examples:

```
2026-09-10_2030_v0.4_black-screen.log
2026-09-11_1802_v0.4_debug1-empty-voxels.log
2026-09-12_2145_v0.5_noise-not-denoised.log
```

Optional: add a same-named `.txt` note with preset, dimension, time of day,
steps to reproduce and expected vs. actual result.

Then share the raw URL:

```
https://raw.githubusercontent.com/<user>/<repo>/main/logs/<file>.log
```

The repository must be public. See `../LOGS.md` for the full workflow.
