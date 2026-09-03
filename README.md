# pihole-adlists

Custom Pi-hole blocklist for blocking entire TLDs (Top-Level Domains), used across my Pi-hole instances.

## Structure

    .
    ├── docker/
    │   └── tld-updater/       # Container that automatically refreshes the TLD list
    │       ├── Dockerfile
    │       ├── crontab        # schedule for automatic updates
    │       ├── run.sh          # main update/commit/push logic
    │       └── next-run.sh     # calculates and logs the next scheduled run
    ├── scripts/
    │   ├── get-tld.sh          # builds tld/tld.txt from sources/tld-sources.txt
    │   └── tld-whitelist.txt   # TLDs to exclude from blocking
    ├── sources/
    │   └── tld-sources.txt     # URL(s) of the raw TLD list(s) to download
    └── tld/
        └── tld.txt             # generated Pi-hole adlist (Adblock Plus syntax)

## How it works

1. `scripts/get-tld.sh` downloads the current TLD list from the source(s) listed in `sources/tld-sources.txt`.
2. Any TLD listed in `scripts/tld-whitelist.txt` is excluded from the result.
3. The remaining TLDs are written to `tld/tld.txt` in Adblock Plus format, ready to be added as a Pi-hole adlist.
4. Pi-hole pulls this file directly via:

    https://raw.githubusercontent.com/owentrafalgar/pihole-adlists/refs/heads/main/tld/tld.txt

## Automatic updates

The `docker/tld-updater` container runs on a schedule (see `docker/tld-updater/crontab`) and:
- pulls the latest repo state,
- re-runs `get-tld.sh`,
- commits and pushes `tld/tld.txt` if it changed.

Logs are visible via `docker logs tld-updater` (or Dozzle), and a status file at `/status/tld-updater.status`
is used by a Checkmk local check (piggybacked to a `tld-updater` host) to alert if a run fails or hasn't
run recently.

### Changing the schedule

Edit `docker/tld-updater/crontab` (standard 5-field cron syntax), commit, and rebuild the container.
`next-run.sh` reads this file dynamically, so the "next scheduled run" log line always reflects the
current schedule without needing separate changes.

## Maintaining the whitelist

If a legitimate TLD ends up blocked (breaking normal DNS resolution, e.g. reverse lookups via
`.arpa`, or a real service using an unusual TLD), add it to `scripts/tld-whitelist.txt` (one per line,
`#` for comments) and let the next scheduled run (or a manual run) regenerate `tld/tld.txt`.

## Manual run

    docker exec tld-updater /run.sh
