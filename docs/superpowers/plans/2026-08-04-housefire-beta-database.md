# Writable Housefire Beta Database Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a writable `housefire_beta` database and role to the existing Raspberry Pi PostgreSQL/PgBouncer installation, with an explicit low-storage refresh command and separate beta application wiring.

**Architecture:** Keep one PostgreSQL 18 cluster and one PgBouncer instance. Add an opt-in `housefire_beta` database, a dedicated five-connection `housefire_beta` role, and a PgBouncer mapping for that database. Install two focused shell programs: one streams a production dump into a destructively refreshed beta database only after `refresh --confirm`, and the other applies the beta SCRAM verifier from the SOPS-managed userlist without logging it.

**Tech Stack:** NixOS modules, PostgreSQL 18, PgBouncer transaction pooling, systemd oneshot services, Bash, SOPS-Nix, shell assertions, and Nix flake checks.

## Global Constraints

- Use the exact database and role names `housefire_beta`.
- Keep the production `housefire` database, role, PgBouncer mapping, and ticker services unchanged.
- Never drop or recreate `housefire`; the refresh command may drop only `housefire_beta`.
- Require the exact destructive command form `housefire-beta-db refresh --confirm`.
- Stream `pg_dump --no-owner --no-acl` into `psql --role=housefire_beta` instead of writing a second full dump to disk.
- Keep beta PostgreSQL connections capped at five and beta PgBouncer pooling small.
- Do not commit, print, or include real database passwords, SCRAM verifiers, API keys, or `.env` content.
- Store the beta SCRAM verifier as a second entry in the existing SOPS-managed PgBouncer userlist.
- Preserve the existing two-space Nix formatting and run `nix fmt` after edits.
- Verify with the shell tests, `nix flake check`, and a target-specific `rbpi-nixos` build before claiming completion.

## File Map

- Create: `nix_modules/housefire-beta-db.sh` — root-only, confirmation-gated production-to-beta refresh command.
- Create: `nix_modules/housefire-beta-sync-credentials.sh` — extracts and applies only the beta SCRAM verifier.
- Create: `nix_modules/housefire_beta.nix` — opt-in beta database, role, PgBouncer, systemd, and package wiring.
- Create: `nix_modules/tests/housefire-beta-db-test.sh` — static safety checks for the destructive refresh script.
- Create: `nix_modules/tests/housefire-beta-sync-credentials-test.sh` — fixture-backed credential extraction and SQL-shape checks.
- Create: `docs/housefire-beta.md` — secret-safe operator runbook for bootstrapping credentials, refreshing beta, and configuring the beta app.
- Create: `docs/superpowers/plans/2026-08-04-housefire-beta-database.md` — this implementation plan.
- Modify: `nix_modules/postgres.nix` — allow multiple modules to append authentication lines.
- Modify: `flake.nix` — import the beta module in `rbpi-nixos` only.
- Modify: `rbpi/secrets.nix` — make the existing userlist readable by PostgreSQL and PgBouncer and restart the beta credential unit when it changes.

---

### Task 1: Add failing safety and credential tests

**Files:**

- Create: `nix_modules/tests/housefire-beta-db-test.sh`
- Create: `nix_modules/tests/housefire-beta-sync-credentials-test.sh`
- Test: both new shell tests

**Interfaces:**

- Consumes: the future scripts `nix_modules/housefire-beta-db.sh` and `nix_modules/housefire-beta-sync-credentials.sh`.
- Produces: failing tests that define the refresh safety contract and the credential-sync behavior before implementation.

- [ ] **Step 1: Write the refresh safety test**

Create `nix_modules/tests/housefire-beta-db-test.sh`:

```bash
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
assert_contains "$script" '--role="$beta_role"'
assert_contains "$script" 'set -o pipefail'

if grep -Fq -- 'DROP DATABASE IF EXISTS "housefire"' "$script"; then
  printf 'refresh script contains a production database drop\n' >&2
  exit 1
fi
```

- [ ] **Step 2: Write the credential-sync test with a fake userlist and fake `runuser`**

Create `nix_modules/tests/housefire-beta-sync-credentials-test.sh`:

```bash
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
```

- [ ] **Step 3: Make both test files executable**

Run:

```sh
chmod +x nix_modules/tests/housefire-beta-db-test.sh nix_modules/tests/housefire-beta-sync-credentials-test.sh
```

- [ ] **Step 4: Run the tests and verify they fail for missing implementation files**

Run:

```sh
bash nix_modules/tests/housefire-beta-db-test.sh
bash nix_modules/tests/housefire-beta-sync-credentials-test.sh
```

Expected: the first test exits nonzero at `test -f` because `housefire-beta-db.sh` does not exist. The second test exits nonzero at `test -f` because `housefire-beta-sync-credentials.sh` does not exist. Do not treat these expected failures as implementation failures.

- [ ] **Step 5: Commit the failing tests**

```sh
git add nix_modules/tests/housefire-beta-db-test.sh nix_modules/tests/housefire-beta-sync-credentials-test.sh
git commit -m "test: define housefire beta database safety contracts"
```

### Task 2: Implement the confirmation-gated beta refresh command

**Files:**

- Create: `nix_modules/housefire-beta-db.sh`
- Test: `nix_modules/tests/housefire-beta-db-test.sh`

**Interfaces:**

- Consumes: the local PostgreSQL socket, production database `housefire`, beta role `housefire_beta`, and beta database `housefire_beta`.
- Produces: `housefire-beta-db refresh --confirm`, which recreates only the beta database and streams a production snapshot into it.

- [ ] **Step 1: Add the minimal refresh implementation**

Create `nix_modules/housefire-beta-db.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly production_database='housefire'
readonly beta_database='housefire_beta'
readonly beta_role='housefire_beta'

die() {
  printf 'housefire-beta-db: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'usage: housefire-beta-db refresh --confirm\n' >&2
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
```

The constants are intentionally fixed to the two database names so a command typo cannot redirect the destructive operation to another database. The `pg_dump` pipeline runs as PostgreSQL’s operating-system user, while `psql --role=housefire_beta` makes restored objects owned by the beta role.

- [ ] **Step 2: Make the script executable**

Run:

```sh
chmod +x nix_modules/housefire-beta-db.sh
```

- [ ] **Step 3: Run the focused refresh test and shell syntax check**

Run:

```sh
bash nix_modules/tests/housefire-beta-db-test.sh
bash -n nix_modules/housefire-beta-db.sh
```

Expected: both commands exit 0. The test checks that refresh requires the confirmation flag, uses a streaming no-owner/no-ACL dump, targets `housefire_beta`, and contains no production database drop.

- [ ] **Step 4: Commit the refresh command**

```sh
git add nix_modules/housefire-beta-db.sh nix_modules/tests/housefire-beta-db-test.sh
git commit -m "feat: add writable housefire beta refresh command"
```

### Task 3: Implement SCRAM credential synchronization

**Files:**

- Create: `nix_modules/housefire-beta-sync-credentials.sh`
- Test: `nix_modules/tests/housefire-beta-sync-credentials-test.sh`

**Interfaces:**

- Consumes: `HOUSEFIRE_USERLIST_PATH`, defaulting to `/var/lib/pgbouncer/userlist.txt`, containing a SCRAM entry named `housefire_beta`.
- Produces: a root-run command that sends one validated `ALTER ROLE "housefire_beta" PASSWORD ...` statement to local PostgreSQL without printing the verifier.

- [ ] **Step 1: Add the credential synchronization implementation**

Create `nix_modules/housefire-beta-sync-credentials.sh`:

```bash
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

if ! printf '%s\n' "$verifier" | grep -Eq '^SCRAM-SHA-256\$[0-9]+:[A-Za-z0-9+/=]+\$[A-Za-z0-9+/=]+:[A-Za-z0-9+/=]+$'; then
  die "userlist entry for ${beta_role} is not a valid SCRAM verifier"
fi

printf "ALTER ROLE \"%s\" PASSWORD '%s';\n" "$beta_role" "$verifier" |
  runuser --user postgres -- psql \
    --no-psqlrc \
    --set=ON_ERROR_STOP=1 \
    --dbname=postgres
```

The verifier is validated before entering SQL, and the only diagnostic messages contain the file path or role name. The SQL travels over standard input so it is not placed in the process argument list.

- [ ] **Step 2: Make the script executable and run its fixture-backed test**

Run:

```sh
chmod +x nix_modules/housefire-beta-sync-credentials.sh
bash nix_modules/tests/housefire-beta-sync-credentials-test.sh
bash -n nix_modules/housefire-beta-sync-credentials.sh
```

Expected: the test exits 0, confirms that only the beta verifier reaches the fake `runuser`, and confirms a userlist without a beta entry fails.

- [ ] **Step 3: Commit credential synchronization**

```sh
git add nix_modules/housefire-beta-sync-credentials.sh nix_modules/tests/housefire-beta-sync-credentials-test.sh
git commit -m "feat: sync housefire beta postgres credentials"
```

### Task 4: Add the opt-in NixOS beta module

**Files:**

- Create: `nix_modules/housefire_beta.nix`
- Modify: `nix_modules/postgres.nix:17-21`
- Test: `nix_modules/tests/housefire-beta-db-test.sh`, `nix_modules/tests/housefire-beta-sync-credentials-test.sh`

**Interfaces:**

- Consumes: the two scripts from Tasks 2 and 3, the existing `nix_postgres` module, and `config.sops.secrets.housefireUserlist.path`.
- Produces: NixOS declarations for the beta database, role, authentication, PgBouncer mapping, refresh package, and credential-sync service.

- [ ] **Step 1: Change the authentication-line option to a mergeable line type**

In `nix_modules/postgres.nix`, change only the `extraAuthLines` option type:

```nix
extraAuthLines = lib.mkOption {
  default = "";
  type = lib.types.lines;
};
```

This lets the existing production Housefire module and the beta module append independent `pg_hba.conf` lines without one module replacing the other.

- [ ] **Step 2: Add the beta module**

Create `nix_modules/housefire_beta.nix`:

```nix
{
  lib,
  pkgs,
  config,
  ...
}:

let
  housefireBetaDb = pkgs.writeShellApplication {
    name = "housefire-beta-db";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.postgresql_18
      pkgs.util-linux
    ];
    text = builtins.readFile ./housefire-beta-db.sh;
  };

  housefireBetaSyncCredentials = pkgs.writeShellApplication {
    name = "housefire-beta-sync-credentials";
    runtimeInputs = [
      pkgs.gawk
      pkgs.gnugrep
      pkgs.postgresql_18
      pkgs.util-linux
    ];
    text = builtins.readFile ./housefire-beta-sync-credentials.sh;
  };
in
{
  imports = [ ./postgres.nix ];

  environment.systemPackages = [ housefireBetaDb ];

  services.postgresql = {
    ensureDatabases = lib.mkAfter [ "housefire_beta" ];
    ensureUsers = lib.mkAfter [
      {
        name = "housefire_beta";
        ensureDBOwnership = true;
        ensureClauses.connection_limit = 5;
      }
    ];
  };

  nix_postgres = {
    extraAuthLines = ''
      local sameuser  housefire_beta     scram-sha-256
      host  sameuser  housefire_beta     all              scram-sha-256
    '';
    pgbouncerDatabases.housefire_beta =
      "host=/run/postgresql dbname=housefire_beta user=housefire_beta pool_size=5 ";
  };

  systemd.services.housefire-beta-sync-credentials = {
    description = "Synchronize the Housefire beta PostgreSQL SCRAM verifier";
    after = [
      "postgresql-setup.service"
      "sops-install-secrets.service"
    ];
    before = [ "pgbouncer.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    environment.HOUSEFIRE_USERLIST_PATH = config.sops.secrets.housefireUserlist.path;
    script = "${housefireBetaSyncCredentials}/bin/housefire-beta-sync-credentials";
  };

  systemd.services.pgbouncer = {
    wants = [ "housefire-beta-sync-credentials.service" ];
    after = [ "housefire-beta-sync-credentials.service" ];
  };
}
```

- [ ] **Step 3: Extend the static tests with module invariants**

Add these assertions to `nix_modules/tests/housefire-beta-db-test.sh` after the refresh assertions:

```bash
module="$script_dir/housefire_beta.nix"
test -f "$module"
grep -Fq -- 'ensureDatabases = lib.mkAfter [ "housefire_beta" ]' "$module"
grep -Fq -- 'name = "housefire_beta"' "$module"
grep -Fq -- 'connection_limit = 5' "$module"
grep -Fq -- 'pgbouncerDatabases.housefire_beta' "$module"
grep -Fq -- 'housefire-beta-sync-credentials.service' "$module"
```

- [ ] **Step 4: Run focused tests and format the Nix module**

Run:

```sh
bash nix_modules/tests/housefire-beta-db-test.sh
bash nix_modules/tests/housefire-beta-sync-credentials-test.sh
nix fmt
```

Expected: both shell tests exit 0 and the formatter exits 0. The existing production authentication lines must remain present in `nix_modules/housefire.nix`.

- [ ] **Step 5: Commit the module and option merge change**

```sh
git add nix_modules/housefire_beta.nix nix_modules/postgres.nix nix_modules/tests/housefire-beta-db-test.sh
git commit -m "feat: wire housefire beta into nixos postgres"
```

### Task 5: Import beta on the Raspberry Pi and wire the SOPS userlist

**Files:**

- Modify: `flake.nix:72-78`
- Modify: `rbpi/secrets.nix:16-22`
- Test: `nix_modules/tests/housefire-beta-db-test.sh`

**Interfaces:**

- Consumes: `nix_modules/housefire_beta.nix` and the existing SOPS-managed `housefireUserlist` secret.
- Produces: an `rbpi-nixos` system that includes beta infrastructure while leaving Darwin and standalone Home Manager outputs unchanged.

- [ ] **Step 1: Import the beta module only in `rbpi-nixos`**

In the Raspberry Pi module list in `flake.nix`, place the beta import directly after the existing Housefire import:

```nix
./nix_modules/housefire.nix
./nix_modules/housefire_beta.nix
./nix_modules/ddns.nix
```

Do not add the module to `darwinConfigurations` or any `homeConfigurations` output.

- [ ] **Step 2: Allow PostgreSQL credential sync and PgBouncer to read the existing userlist**

In `rbpi/secrets.nix`, keep the existing encrypted file and secret name, and set the `housefireUserlist` metadata to:

```nix
sops.secrets.housefireUserlist = {
  format = "binary";
  sopsFile = ./secrets/housefire_userlist.txt;
  owner = "postgres";
  group = "pgbouncer";
  mode = "0440";
  path = "/var/lib/pgbouncer/userlist.txt";
  restartUnits = [
    "pgbouncer.service"
    "housefire-beta-sync-credentials.service"
  ];
};
```

Preserve the repository’s existing encrypted `sopsFile` declaration if its path differs from the example above; do not print or replace its encrypted contents.

- [ ] **Step 3: Add a beta userlist entry without exposing its value**

After the NixOS configuration creates the role, set a password interactively and retrieve its SCRAM verifier only for immediate insertion into the encrypted userlist:

```sh
sudo -u postgres psql --no-psqlrc postgres
```

At the `psql` prompt, run:

```sql
\password housefire_beta
\q
```

Retrieve the verifier directly to the terminal, without redirecting it to a log:

```sh
sudo -u postgres psql --no-psqlrc -Atqc \
  "SELECT rolpassword FROM pg_authid WHERE rolname = 'housefire_beta';"
```

Use `sops rbpi/secrets/housefire_userlist.txt` to add one `housefire_beta` line in the same quoted userlist format as the production entry, using that verifier. Save the encrypted file and do not paste the verifier into Git-tracked files, shell history, commit messages, or documentation.

- [ ] **Step 4: Add test assertions for host wiring**

Append these checks to `nix_modules/tests/housefire-beta-db-test.sh`:

```bash
flake="$script_dir/../../flake.nix"
secrets="$script_dir/../../rbpi/secrets.nix"
grep -Fq -- './nix_modules/housefire_beta.nix' "$flake"
grep -Fq -- 'group = "pgbouncer"' "$secrets"
grep -Fq -- 'housefire-beta-sync-credentials.service' "$secrets"
```

- [ ] **Step 5: Run the focused tests and inspect the diff for secrets**

Run:

```sh
bash nix_modules/tests/housefire-beta-db-test.sh
bash nix_modules/tests/housefire-beta-sync-credentials-test.sh
git diff --check
git diff -- flake.nix rbpi/secrets.nix nix_modules/housefire_beta.nix
```

Expected: tests pass; the diff contains only secret metadata and module wiring, never an encrypted-file plaintext value or password.

- [ ] **Step 6: Commit Raspberry Pi wiring**

```sh
git add flake.nix rbpi/secrets.nix nix_modules/tests/housefire-beta-db-test.sh
git commit -m "feat: enable housefire beta on rbpi"
```

### Task 6: Document beta bootstrap, refresh, and application configuration

**Files:**

- Create: `docs/housefire-beta.md`
- Test: `git diff --check`

**Interfaces:**

- Consumes: the NixOS module’s command, database names, PgBouncer port, and SvelteKit environment contract.
- Produces: a secret-safe operator runbook that supports a writable beta deployment without changing production service configuration.

- [ ] **Step 1: Write the operator runbook**

Create `docs/housefire-beta.md` with these sections and commands:

```markdown
# Housefire beta environment

The beta environment uses the same PostgreSQL 18 cluster as production, but a separate database and login role:

- database: `housefire_beta`
- role: `housefire_beta`
- runtime PgBouncer port: `6432`
- direct Prisma/migration port: `5432`

## Activate the infrastructure

Build first, then switch the Raspberry Pi configuration:

```sh
nix fmt
nix flake check
sudo nixos-rebuild build --flake .#rbpi-nixos
sudo nixos-rebuild switch --flake .#rbpi-nixos
```

## Configure the beta credential

Choose the beta role password interactively with PostgreSQL’s `\\password` command. Retrieve its SCRAM verifier only in the terminal, add it as a second entry in the encrypted `rbpi/secrets/housefire_userlist.txt` userlist with `sops`, and restart the credential-sync and PgBouncer units if SOPS did not restart them automatically:

```sh
sudo systemctl restart housefire-beta-sync-credentials.service
sudo systemctl restart pgbouncer.service
```

Never put the password or SCRAM verifier in this repository, shell history, logs, or a commit.

## Refresh beta from production

Refreshing is destructive to beta and does not modify production:

```sh
sudo housefire-beta-db refresh --confirm
```

The command takes a consistent production dump, recreates only `housefire_beta`, restores data as `housefire_beta`, and analyzes the refreshed database. Do not run it while beta data must be preserved.

## Configure the beta SvelteKit deployment

Set separate beta deployment secrets. Use the beta role and database in both URLs; use PgBouncer for runtime traffic and PostgreSQL directly for Prisma CLI commands:

```text
DB_URL=postgresql://housefire_beta:<beta-password>@rbpi.liammurphydev.com:6432/housefire_beta
DB_URL_DIRECT=postgresql://housefire_beta:<beta-password>@rbpi.liammurphydev.com:5432/housefire_beta
SELF_API_KEY=<beta-only-api-key>
```

Apply tracked migrations against `DB_URL_DIRECT` before deploying code that requires them:

```sh
npm run db:migrate
```

Keep the beta API key separate from the production API key.

## Point the Python scraper at beta

Create a private Housefire CLI config with the beta API base URL ending in `/api/`, the beta API key, the beta deployment environment, and private temporary/log directories. From the Python scraper repository, run the existing CLI with that config path, for example:

```sh
cd /path/to/python_serverless_housefire
nix run . -- --config-path /private/path/housefire-beta.ini run-data-pipeline pld
```

Do not change the production `~/.config/housefire/default.ini` or the existing production systemd ticker services.

## Verify isolation

Use the beta direct URL to confirm the database and role, then perform a beta API create/update/delete smoke test with the beta API key. Verify production through its existing application path and confirm that beta-only records are absent there.
```

Replace only the angle-bracketed values in the deployment system; never replace them with real values in this repository.

- [ ] **Step 2: Check documentation formatting and secret hygiene**

Run:

```sh
git diff --check
rg -n 'SCRAM-SHA-256\\$[0-9]+:|postgres(ql)?://[^ ]+:[^ ]+@|SELF_API_KEY=.*[A-Za-z0-9]{20,}' docs/housefire-beta.md || true
```

Expected: `git diff --check` exits 0 and the secret scan produces no matching real credential lines.

- [ ] **Step 3: Commit the runbook**

```sh
git add docs/housefire-beta.md
git commit -m "docs: document housefire beta operations"
```

### Task 7: Run repository and target verification

**Files:**

- Test: all changed Nix and shell files

**Interfaces:**

- Consumes: the complete beta module, scripts, host wiring, secret metadata, tests, and runbook.
- Produces: fresh evidence that the flake evaluates, the target system builds, shell safety checks pass, and no unintended files or secret values are staged.

- [ ] **Step 1: Run all focused shell tests**

Run:

```sh
bash nix_modules/tests/housefire-beta-db-test.sh
bash nix_modules/tests/housefire-beta-sync-credentials-test.sh
```

Expected: both commands exit 0.

- [ ] **Step 2: Format the Nix sources**

Run:

```sh
nix fmt
```

Expected: the configured formatter exits 0 and only intended Nix files change.

- [ ] **Step 3: Evaluate the flake checks**

Run:

```sh
nix flake check
```

Expected: exit 0, including evaluation of `rbpi-nixos` with the beta module, PostgreSQL `types.lines` merge, and SOPS secret metadata.

- [ ] **Step 4: Build the Raspberry Pi target**

Run:

```sh
sudo nixos-rebuild build --flake .#rbpi-nixos
```

Expected: exit 0 and a system derivation containing `housefire-beta-db`, the beta systemd unit, PostgreSQL 18, and the PgBouncer configuration.

- [ ] **Step 5: Inspect the final change set**

Run:

```sh
git diff --check
git status --short
git diff --stat HEAD~6..HEAD
git diff HEAD~6..HEAD -- ':!rbpi/secrets/**' ':!rbpi/secrets.nix'
```

Expected: all tests and checks are clean; only the planned module, scripts, tests, documentation, flake wiring, PostgreSQL option type, and secret metadata are changed; no `.env`, generated output, or plaintext secret appears.

- [ ] **Step 6: Record post-activation manual verification for the operator**

After the operator has activated the configuration and supplied the beta userlist entry, verify without printing credentials:

```sh
systemctl is-active postgresql pgbouncer
sudo -u postgres psql --no-psqlrc -Atqc \
  "SELECT datname FROM pg_database WHERE datname IN ('housefire', 'housefire_beta') ORDER BY datname;"
sudo -u postgres psql --no-psqlrc -Atqc \
  "SELECT rolname FROM pg_roles WHERE rolname IN ('housefire', 'housefire_beta') ORDER BY rolname;"
sudo systemctl status housefire-beta-sync-credentials.service --no-pager
```

Then run the beta application migration and a beta-only write smoke test. Confirm the production application does not display the beta-only record. Do not claim the live environment is operational until these checks have been run on the Raspberry Pi.

- [ ] **Step 7: Commit any formatter-only changes and the verified final state**

```sh
git add flake.nix nix_modules/postgres.nix nix_modules/housefire_beta.nix nix_modules/housefire-beta-db.sh nix_modules/housefire-beta-sync-credentials.sh nix_modules/tests/housefire-beta-db-test.sh nix_modules/tests/housefire-beta-sync-credentials-test.sh rbpi/secrets.nix docs/housefire-beta.md
git commit -m "feat: finish writable housefire beta environment"
```
