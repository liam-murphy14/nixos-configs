#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$script_dir/housefire-beta-sync-credentials.sh"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

userlist="$test_dir/userlist.txt"
sql_output="$test_dir/sql.txt"
cat > "$userlist" <<'EOF'
"housefire" "SCRAM-SHA-256$4096:prod-salt=:prod-key="
"housefire_beta" "SCRAM-SHA-256$4096:beta-salt=:beta-key="
EOF

cat > "$test_dir/runuser" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
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
grep -Fq -- 'SCRAM-SHA-256$4096:beta-salt=:beta-key=' "$sql_output"
if grep -Fq -- 'prod-salt' "$sql_output"; then
  printf 'credential sync selected the production verifier\n' >&2
  exit 1
fi

missing_userlist="$test_dir/missing-beta.txt"
printf '%s\n' '"housefire" "SCRAM-SHA-256$4096:prod-salt=:prod-key="' > "$missing_userlist"
if PATH="$test_dir:$PATH" HOUSEFIRE_USERLIST_PATH="$missing_userlist" HOUSEFIRE_TEST_SQL="$sql_output" bash "$script"; then
  printf 'credential sync accepted a userlist without housefire_beta\n' >&2
  exit 1
fi
