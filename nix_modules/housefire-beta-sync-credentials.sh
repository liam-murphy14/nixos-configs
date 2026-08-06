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
      count++
      if (count == 1) {
        value = $2
        gsub(/^"|"$/, "", value)
      }
    }
    END {
      if (count != 1) exit 1
      print value
    }
  ' "$userlist_path"
)" || die "userlist must contain exactly one ${beta_role} entry"

if ! printf '%s\n' "$verifier" | grep -Eq '^SCRAM-SHA-256[$][0-9]+:([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})[$]([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4}):([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})$'; then
  die "userlist entry for ${beta_role} is not a valid SCRAM verifier"
fi

printf "ALTER ROLE \"%s\" PASSWORD '%s';\n" "$beta_role" "$verifier" |
  runuser --user postgres -- psql \
    --no-psqlrc \
    --set=ON_ERROR_STOP=1 \
    --dbname=postgres
