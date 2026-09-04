# pihole-adlists

Custom Pi-hole blocklist for blocking entire TLDs (Top-Level Domains), used across my Pi-hole instances.

## Structure

    .
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

This list is kept up to date automatically by [git-cron-runner](https://github.com/owentrafalgar/git-cron-runner),
a generic container that clones this repo, runs `scripts/get-tld.sh` on a schedule, and commits/pushes
`tld/tld.txt` if it changed. See that repo for the container itself, configuration, and monitoring details
(logs, Checkmk status file, etc.).

## Maintaining the whitelist

If a legitimate TLD ends up blocked (breaking normal DNS resolution, e.g. reverse lookups via
`.arpa`, or a real service using an unusual TLD), add it to `scripts/tld-whitelist.txt` (one per line,
`#` for comments) and let the next scheduled run (or a manual run) regenerate `tld/tld.txt`.

## Manual run

    bash scripts/get-tld.sh
