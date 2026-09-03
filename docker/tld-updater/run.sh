#!/bin/bash
set -euo pipefail

REPO_DIR="/repo"
REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/pihole-adlists.git"
STATUS_DIR="/status"
STATUS_FILE="$STATUS_DIR/tld-updater.status"

mkdir -p "$STATUS_DIR"

echo "=== $(date) : Starting TLD list update ==="

EXIT_CODE=0

{
    if [ ! -d "$REPO_DIR/.git" ]; then
        echo "Cloning repo..."
        git clone "$REPO_URL" "$REPO_DIR"
    else
        echo "Pulling latest changes..."
        cd "$REPO_DIR"
        git pull
    fi

    git config --global user.email "tld-updater@mytwoquarters.com"
    git config --global user.name "TLD Updater Bot"

    cd "$REPO_DIR/scripts"
    bash get-tld.sh

    cd "$REPO_DIR"
    if [ -n "$(git status --porcelain)" ]; then
        echo "Changes detected, committing..."
        git add tld/tld.txt
        git commit -m "Auto-update TLD list ($(date +%Y-%m-%d))"
        git push
        echo "Pushed changes."
    else
        echo "No changes."
    fi
} || EXIT_CODE=$?

echo "TIMESTAMP=$(date +%s)" > "$STATUS_FILE"
echo "EXIT_CODE=$EXIT_CODE" >> "$STATUS_FILE"

echo "=== $(date) : Done (exit code $EXIT_CODE) ==="
exit $EXIT_CODE
