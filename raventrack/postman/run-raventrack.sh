#!/usr/bin/env bash
# Same as run-raventrack.ps1, for macOS/Linux.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
env_file="${1:-$dir/RavenTrack.postman_environment.local.json}"
[ -f "$env_file" ] || { echo "Missing $env_file - copy the template and add your refresh_token." >&2; exit 1; }
newman run "$dir/RavenTrack-Automated.postman_collection.json" \
  --environment "$env_file" --export-environment "$env_file" --reporters cli
