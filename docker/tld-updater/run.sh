#!/bin/bash
set -uo pipefail

REPO_DIR="/repo"
REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/pihole-adlists.git"
STATUS_DIR="/status"
STATUS_FILE="$STATUS_DIR/tld-updater.status"

mkdir -p "$STATUS_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TLD updater: starting"

EXIT_CODE=0
RESULT_MSG=""

if [ ! -d "$REPO_DIR/.git" ]; then
    git clone --quiet "$REPO_URL" "$REPO_DIR" || EXIT_CODE=$?
else
    cd "$REPO_DIR"
    git pull --quiet || EXIT_CODE=$?
fi

if [ "$EXIT_CODE" -eq 0 ]; then
    git config --global user.email "tld-updater@mytwoquarters.com"
    git config --global user.name "TLD Updater Bot"

    cd "$REPO_DIR/scripts"
    if bash get-tld.sh; then
        cd "$REPO_DIR"
        if [ -n "$(git status --porcelain)" ]; then
            if git add tld/tld.txt && \
               git commit --quiet -m "Auto-update TLD list ($(date +%Y-%m-%d))" && \
               git push --quiet; then
                RESULT_MSG="changes pushed"
            else
                EXIT_CODE=1
                RESULT_MSG="git commit/push failed"
            fi
        else
            RESULT_MSG="no changes"
        fi
    else
        EXIT_CODE=$?
        RESULT_MSG="get-tld.sh failed"
    fi
fi

echo "TIMESTAMP=$(date +%s)" > "$STATUS_FILE"
echo "EXIT_CODE=$EXIT_CODE" >> "$STATUS_FILE"

if [ "$EXIT_CODE" -ne 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TLD updater: FAILED - $RESULT_MSG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TLD updater: success - $RESULT_MSG"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TLD updater: finished"

/next-run.sh

exit "$EXIT_CODE"
