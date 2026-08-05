#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$script_dir/housefire-beta-db.sh"

assert_contains() {
  local file="$1"
  local text="$2"
  if ! grep -Fq -- "$text" "$file"; then
    printf 'missing required text in %s: %s\n' "$file" "$text" >&2
    exit 1
  fi
}

assert_matches() {
  local file="$1"
  local pattern="$2"
  if ! grep -Eq -- "$pattern" "$file"; then
    printf 'missing required pattern in %s: %s\n' "$file" "$pattern" >&2
    exit 1
  fi
}

test -f "$script"
bash -n "$script"
assert_contains "$script" 'refresh --confirm'
assert_contains "$script" 'DROP DATABASE IF EXISTS "housefire_beta" WITH (FORCE);'
assert_contains "$script" 'CREATE DATABASE "housefire_beta" OWNER "housefire_beta";'
assert_matches "$script" 'pg_dump[[:space:]].*--no-owner.*--no-acl.*\|[[:space:]]*psql[[:space:]]+--role="\$beta_role"'
assert_contains "$script" 'set -o pipefail'

if grep -Eq -- '(^|[^[:alnum:]_])housefire([^[:alnum:]_]|$)' "$script"; then
  printf 'refresh script contains a standalone production database target\n' >&2
  exit 1
fi
