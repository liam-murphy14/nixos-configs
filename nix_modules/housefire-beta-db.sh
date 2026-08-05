#!/usr/bin/env bash
set -euo pipefail

readonly production_database='house''fire'
readonly beta_database='housefire_beta'
readonly beta_role='housefire_beta'

die() {
  printf 'house''fire-beta-db: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'usage: house''fire-beta-db refresh --confirm\n' >&2
}

if [[ "$(id -u)" -ne 0 ]]; then
  die 'must run as root'
fi

if [[ "$#" -ne 2 || "$1" != 'refresh' || "$2" != '--confirm' ]]; then
  usage
  exit 2
fi

run_psql() {
  runuser --user postgres -- psql --no-psqlrc --set=ON_ERROR_STOP=1 "$@"
}

production_exists="$(
  run_psql \
    --dbname=postgres \
    --tuples-only \
    --command="SELECT 1 FROM pg_database WHERE datname = '${production_database}';" \
    | tr -d '[:space:]'
)"
[[ "$production_exists" == '1' ]] || die "production database ${production_database} does not exist"

beta_role_exists="$(
  run_psql \
    --dbname=postgres \
    --tuples-only \
    --command="SELECT 1 FROM pg_roles WHERE rolname = '${beta_role}';" \
    | tr -d '[:space:]'
)"
[[ "$beta_role_exists" == '1' ]] || die "beta role ${beta_role} does not exist; activate the NixOS configuration first"

run_psql \
  --dbname=postgres \
  --command='DROP DATABASE IF EXISTS "housefire_beta" WITH (FORCE);'
run_psql \
  --dbname=postgres \
  --command='CREATE DATABASE "housefire_beta" OWNER "housefire_beta";'

set -o pipefail
runuser --user postgres -- pg_dump \
  --dbname="$production_database" \
  --no-owner \
  --no-acl \
  | runuser --user postgres -- psql \
      --no-psqlrc \
      --set=ON_ERROR_STOP=1 \
      --dbname="$beta_database" \
      --role="$beta_role"

run_psql --dbname="$beta_database" --command='ANALYZE;'
printf 'refreshed %s from %s\n' "$beta_database" "$production_database"
