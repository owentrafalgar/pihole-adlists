#!/bin/bash
set -euo pipefail

REPO_DIR="/repo"
REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/pihole-adlists.git"

echo "=== $(date) : Starting TLD list update ==="

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

echo "=== $(date) : Done ==="
