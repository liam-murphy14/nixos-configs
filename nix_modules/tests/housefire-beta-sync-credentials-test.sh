#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$script_dir/housefire-beta-sync-credentials.sh"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

userlist="$test_dir/userlist.txt"
sql_output="$test_dir/sql.txt"
cat > "$userlist" <<'EOF'
"housefire" "SCRAM-SHA-256$4096:c2FsdC1wcm9kdWN0aW9u$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
"housefire_beta" "SCRAM-SHA-256$4096:c2FsdC1iZXRh$BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=:CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
EOF

cat > "$test_dir/runuser" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if (($# < 3)) || [[ "$1" != '--user' ]] || [[ "$2" != 'postgres' ]]; then
  printf 'fake runuser expected --user postgres\n' >&2
  exit 1
fi
shift 2

psql_seen=false
for arg in "$@"; do
  if [[ "$arg" == 'psql' || "$arg" == */psql ]]; then
    psql_seen=true
    break
  fi
done
if [[ "$psql_seen" != true ]]; then
  printf 'fake runuser expected a psql invocation\n' >&2
  exit 1
fi

cat > "$HOUSEFIRE_TEST_SQL"
EOF
chmod +x "$test_dir/runuser"

test -f "$script"
bash -n "$script"
PATH="$test_dir:$PATH" \
  HOUSEFIRE_USERLIST_PATH="$userlist" \
  HOUSEFIRE_TEST_SQL="$sql_output" \
  bash "$script"

grep -Fq -- 'ALTER ROLE "housefire_beta" PASSWORD' "$sql_output"
grep -Fq -- 'SCRAM-SHA-256$4096:c2FsdC1iZXRh$BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=:CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=' "$sql_output"
if grep -Fq -- 'c2FsdC1wcm9kdWN0aW9u' "$sql_output"; then
  printf 'credential sync selected the production verifier\n' >&2
  exit 1
fi

missing_userlist="$test_dir/missing-beta.txt"
printf '%s\n' '"housefire" "SCRAM-SHA-256$4096:c2FsdC1wcm9kdWN0aW9u$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="' > "$missing_userlist"
if PATH="$test_dir:$PATH" HOUSEFIRE_USERLIST_PATH="$missing_userlist" HOUSEFIRE_TEST_SQL="$sql_output" bash "$script"; then
  printf 'credential sync accepted a userlist without housefire_beta\n' >&2
  exit 1
fi

duplicate_userlist="$test_dir/duplicate-beta.txt"
cat > "$duplicate_userlist" <<'EOF'
"housefire_beta" "SCRAM-SHA-256$4096:c2FsdC1iZXRhLTE$BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=:CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
"housefire_beta" "SCRAM-SHA-256$4096:c2FsdC1iZXRhLTI$DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=:EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE="
EOF
duplicate_sql_output="$test_dir/duplicate-sql.txt"
if PATH="$test_dir:$PATH" HOUSEFIRE_USERLIST_PATH="$duplicate_userlist" HOUSEFIRE_TEST_SQL="$duplicate_sql_output" bash "$script"; then
  printf 'credential sync accepted duplicate housefire_beta entries\n' >&2
  exit 1
fi
