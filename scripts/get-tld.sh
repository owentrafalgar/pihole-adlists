#!/bin/bash
# Builds tld/tld.txt (Adblock Plus syntax) from the TLD source list(s) in
# sources/tld-sources.txt, excluding every TLD listed in scripts/tld-whitelist.txt.
# Can be run from any working directory.
set -euo pipefail

# paths are resolved relative to this script, not the current working directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(dirname "$script_dir")"
sources_path="$repo_dir/sources/tld-sources.txt"
whitelist_path="$script_dir/tld-whitelist.txt"
tld_path="$repo_dir/tld/tld.txt"

# sanity check: abort if the source yields fewer TLDs than this
# (protects against committing an empty/truncated list, e.g. on a broken download)
min_tlds=1000

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -r "$sources_path" ]] || die "Sources file not found: $sources_path"
[[ -r "$whitelist_path" ]] || die "Whitelist file not found: $whitelist_path"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# normalize a list: strip comments, CR (Windows line endings) and whitespace,
# lowercase everything, drop empty lines
normalize() {
    sed -e 's/#.*//' -e 's/\r//g' -e 's/[[:space:]]//g' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | { grep -v '^$' || true; }
}

# download the tld source list(s)
wget -q --timeout=30 --tries=3 -i "$sources_path" -O "$tmp_dir/source.txt" \
    || die "Failed to download TLD source list"

normalize "$whitelist_path" > "$tmp_dir/whitelist.txt"

# keep only valid TLD labels (letters, digits, hyphen; covers punycode "xn--"),
# then remove whitelisted TLDs (exact, fixed-string match)
normalize "$tmp_dir/source.txt" \
    | { grep -E '^[a-z0-9-]+$' || true; } \
    | { grep -vxFf "$tmp_dir/whitelist.txt" || true; } \
    > "$tmp_dir/tlds.txt"

tld_count=$(wc -l < "$tmp_dir/tlds.txt")
(( tld_count >= min_tlds )) \
    || die "Only $tld_count TLDs found (expected at least $min_tlds), keeping existing $tld_path"

# build the complete list in the temp dir first, then replace the target file in one step
{
    cat << 'EOL'
[Adblock Plus]
! Title: TLD list
! Description: Blocks TLDs.
! Syntax: AdBlock
!
!
EOL
    sed 's/.*/||&^/' "$tmp_dir/tlds.txt"
} > "$tmp_dir/tld.txt"

cat "$tmp_dir/tld.txt" > "$tld_path"

echo "TLD list updated: $tld_count TLDs written to $tld_path"
