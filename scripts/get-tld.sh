#!/bin/bash

# variables
work_dir="$(pwd)"
sources_path="$work_dir/../sources/tld-sources.txt"
temp_dir="$work_dir/../temp/"
tld_source_file="tld_source.txt"
tld_file="tld.txt"
tld_source_path="$temp_dir$tld_source_file"
tld_path="$work_dir/../tld/$tld_file"
whitelist_file="tld-whitelist.txt"

# create dynamic whitelist regex from file
tld_whitelist=$(grep -vE '^\s*#|^\s*$' "$whitelist_file" | sed 's/^/^/;s/$/$/' | tr '\n' '|')
tld_whitelist=${tld_whitelist%|}

# creating and cleanup temp dir
mkdir -p "$temp_dir"
rm -f "$temp_dir"*

# download the tld source list
wget -i "$sources_path" -O "$tld_source_path"

# create the header for the adblock plus list
cat > "$tld_path" << EOL
[Adblock Plus]
! Title: TLD list
! Description: Blocks TLDs.
! Syntax: AdBlock
!
!
EOL

# process the downloaded tld source list and append to the tld list

cat "$tld_source_path" | grep -v '^#' | tr '[:upper:]' '[:lower:]' | grep -vE "$tld_whitelist" | sed 's/^/||/' | sed 's/$/^/' | tee -a "$tld_path"
