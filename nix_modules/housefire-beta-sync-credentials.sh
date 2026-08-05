#!/usr/bin/env bash
set -euo pipefail

readonly beta_role='housefire_beta'
readonly userlist_path="${HOUSEFIRE_USERLIST_PATH:-/var/lib/pgbouncer/userlist.txt}"

die() {
  printf 'housefire-beta-sync-credentials: %s\n' "$*" >&2
  exit 1
}

[[ -r "$userlist_path" ]] || die "cannot read PgBouncer userlist at ${userlist_path}"

verifier="$(
  awk -v expected="\"${beta_role}\"" '
    $1 == expected {
      value = $2
      gsub(/^"|"$/, "", value)
      print value
      found = 1
    }
    END {
      if (!found) exit 1
    }
  ' "$userlist_path"
)" || die "userlist has no ${beta_role} entry"

if ! printf '%s\n' "$verifier" | grep -Eq '^SCRAM-SHA-256\$[0-9]+:[A-Za-z0-9+/=_-]+(\$|=):[A-Za-z0-9+/=_-]+$'; then
  die "userlist entry for ${beta_role} is not a valid SCRAM verifier"
fi

printf "ALTER ROLE \"%s\" PASSWORD '%s';\n" "$beta_role" "$verifier" |
  runuser --user postgres -- psql \
    --no-psqlrc \
    --set=ON_ERROR_STOP=1 \
    --dbname=postgres
