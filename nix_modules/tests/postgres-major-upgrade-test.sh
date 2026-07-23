#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
script="$script_dir/postgres-major-upgrade.sh"

test -f "$script"
bash -n "$script"
help_output="$(bash "$script" --help)"
grep -Fq 'backup OLD_MAJOR' <<<"$help_output"
grep -Fq 'migrate OLD_MAJOR NEW_MAJOR BACKUP_DIR' <<<"$help_output"
grep -Fq -- '--no-data-checksums' <<<"$help_output"
