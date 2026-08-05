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

test -f "$script"
bash -n "$script"
assert_contains "$script" 'refresh --confirm'
assert_contains "$script" 'DROP DATABASE IF EXISTS "housefire_beta" WITH (FORCE);'
assert_contains "$script" 'CREATE DATABASE "housefire_beta" OWNER "housefire_beta";'
assert_contains "$script" 'pg_dump'
assert_contains "$script" '--no-owner'
assert_contains "$script" '--no-acl'
assert_contains "$script" 'set -o pipefail'

module="$script_dir/housefire_beta.nix"
test -f "$module"
grep -Fq -- 'ensureDatabases = lib.mkAfter [ "housefire_beta" ]' "$module"
grep -Fq -- 'name = "housefire_beta"' "$module"
grep -Fq -- 'connection_limit = 5' "$module"
grep -Fq -- 'pgbouncerDatabases.housefire_beta' "$module"
grep -Fq -- 'housefire-beta-sync-credentials.service' "$module"

pipeline_segment="$(
  sed -n '/runuser --user postgres -- pg_dump/,/--role="\$beta_role"/p' "$script" |
    tr '\n' ' ' |
    sed -e 's/\\[[:space:]]*/ /g' -e 's/[[:space:]][[:space:]]*/ /g'
)"
expected_pipeline='runuser --user postgres -- pg_dump --dbname="$production_database" --no-owner --no-acl | runuser --user postgres -- psql'
if ! grep -Fq -- "$expected_pipeline" <<< "$pipeline_segment"; then
  printf 'refresh script does not contain the expected direct dump-to-psql pipeline\n' >&2
  exit 1
fi
if ! grep -Fq -- '--role="$beta_role"' <<< "$pipeline_segment"; then
  printf 'refresh script does not associate the direct pipeline with beta role\n' >&2
  exit 1
fi

if grep -Eq -- '(^|[^[:alnum:]_])housefire([^[:alnum:]_]|$)' "$script"; then
  printf 'refresh script contains a standalone production database target\n' >&2
  exit 1
fi

flake="$script_dir/../flake.nix"
secrets="$script_dir/../rbpi/secrets.nix"
grep -Fq -- './nix_modules/housefire_beta.nix' "$flake"
grep -Fq -- 'group = "pgbouncer"' "$secrets"
grep -Fq -- 'housefire-beta-sync-credentials.service' "$secrets"
