#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT

mkdir -p "$temp_dir/.github"
cp "$repo_root/.github/renovate.json" "$temp_dir/.github/renovate.json"
cp "$repo_root/openshift-release.env" "$temp_dir/openshift-release.env"
git -C "$temp_dir" init --quiet
git -C "$temp_dir" add .

if ! (cd "$temp_dir" && renovate --platform=local --dry-run=extract > extraction.log 2>&1); then
  cat "$temp_dir/extraction.log"
  exit 1
fi

if ! rg -q -F '"packageFile": "openshift-release.env"' "$temp_dir/extraction.log" ||
   ! rg -q -F '"depName": "eus-4.22"' "$temp_dir/extraction.log" ||
   ! rg -q -F '"currentValue": "4.21.21"' "$temp_dir/extraction.log" ||
   ! rg -q -F '"datasource": "custom.openshift-releases"' "$temp_dir/extraction.log"; then
  cat "$temp_dir/extraction.log"
  exit 1
fi

printf '%s\n' 'Renovate extracted openshift-release.env as eus-4.22@4.21.21.'
