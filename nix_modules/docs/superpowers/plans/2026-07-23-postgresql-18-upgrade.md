# PostgreSQL 18 Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the Raspberry Pi NixOS PostgreSQL service from PostgreSQL 16.14 to the newest major exposed by the locked flake, PostgreSQL 18.4, with a recoverable on-host migration procedure.

**Architecture:** Pin the reusable `services.postgresql` module to `pkgs.postgresql_18`. Add a standalone Bash helper with separate `backup` and `migrate` phases: the first creates a root-owned logical backup while PostgreSQL 16 is still serving traffic, and the second performs `pg_upgrade` after PostgreSQL 18 has been activated, preserving the old data directory and moving the automatically initialized PostgreSQL 18 directory aside instead of deleting it. PostgreSQL 18's checksum default is handled explicitly by matching the old cluster's checksum setting when reinitializing the new cluster.

**Tech Stack:** NixOS module system, Nix flake, PostgreSQL `pg_upgrade`, Bash, systemd.

## Global Constraints

- Keep the existing two-space Nix formatting and run `nix fmt` after edits.
- Set `services.postgresql.package = pkgs.postgresql_18` because the locked flake exposes PostgreSQL 18.4 as its newest major.
- Never modify or remove `/var/lib/postgresql/16` during the migration; `pg_upgrade` must use its default copy mode.
- Preserve a complete `pg_dumpall` backup before switching the NixOS package.
- Do not expose any values from `rbpi/secrets.nix` or `rbpi/secrets/`.

---

### Task 1: Add a test-first smoke test for the migration helper

**Files:**
- Create: `tests/postgres-major-upgrade-test.sh`
- Test: `postgres-major-upgrade.sh`

**Interfaces:**
- Consumes: the helper's `--help` output and Bash syntax.
- Produces: a repeatable local smoke test that fails until the helper exists and advertises both migration phases.

- [ ] **Step 1: Write the failing test**

Create `tests/postgres-major-upgrade-test.sh`:

```bash
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash tests/postgres-major-upgrade-test.sh
```

Expected: FAIL because `postgres-major-upgrade.sh` does not exist yet.

### Task 2: Add the safe PostgreSQL major-upgrade helper

**Files:**
- Create: `postgres-major-upgrade.sh`
- Test: `tests/postgres-major-upgrade-test.sh`

**Interfaces:**
- Consumes: `backup OLD_MAJOR` before the NixOS switch; `migrate OLD_MAJOR NEW_MAJOR BACKUP_DIR` after the PostgreSQL 18 configuration is active.
- Produces: a backup directory containing `postgresql-<old-major>-all.sql`, a copied-cluster `pg_upgrade` migration, and explicit post-migration validation/rollback instructions.

- [ ] **Step 1: Implement the helper minimally**

The helper must:

1. Require root, `systemctl`, `sudo`, `nix`, and the PostgreSQL client binaries it invokes.
2. In `backup OLD_MAJOR`, confirm the active server major matches `OLD_MAJOR`, create a mode-700 timestamped directory below `/var/backups/postgresql-major-upgrade`, and write a non-empty full `pg_dumpall` SQL dump there with mode 600.
3. In `migrate OLD_MAJOR NEW_MAJOR BACKUP_DIR`, require the backup file, verify `/var/lib/postgresql/<old-major>` exists, resolve the old package with `nix build --no-link --print-out-paths nixpkgs#postgresql_<old-major>.out`, and use `/run/current-system/sw/bin` for the newly activated PostgreSQL binaries.
4. Start PostgreSQL once so NixOS creates the new cluster, then stop `pgbouncer` and `postgresql`. Stop before any `pg_upgrade` work and require the operator to stop application writers separately.
5. Read `Data page checksum version` from the old cluster with the old `pg_controldata` binary. Move the new directory to `/var/lib/postgresql/<new-major>.pre-pg-upgrade-<timestamp>` so the automatically initialized cluster remains recoverable, then run `initdb` with `--no-data-checksums` when the old cluster has checksum version 0 and `--data-checksums` when it has checksum version 1.
6. Run `pg_upgrade --check` first and then the real `pg_upgrade`, without `--link`, from a mode-700 PostgreSQL-owned work directory. Use the exact old and new data directories and binaries.
7. Never remove the old directory or any generated `delete_old_cluster.sh`; print the paths and commands for validation, analyze, restart, and eventual cleanup only after the operator has confirmed the new service.

The core migration invocation must be equivalent to:

```bash
sudo -u postgres "$new_bin/pg_upgrade" \
  -b "$old_bin" \
  -B "$new_bin" \
  -d "/var/lib/postgresql/$old_major" \
  -D "/var/lib/postgresql/$new_major"
```

- [ ] **Step 2: Run the smoke test to verify it passes**

Run:

```bash
bash tests/postgres-major-upgrade-test.sh
```

Expected: PASS, including `bash -n` and the help-contract checks.

### Task 3: Pin the NixOS service to PostgreSQL 18

**Files:**
- Modify: `postgres.nix:26-29`

**Interfaces:**
- Consumes: the locked flake's `pkgs.postgresql_18` package.
- Produces: `rbpi-nixos` configured to use PostgreSQL 18.4 while preserving all existing authentication, database, and PgBouncer settings.

- [ ] **Step 1: Change only the package attribute**

Replace:

```nix
package = pkgs.postgresql_16;
```

with:

```nix
package = pkgs.postgresql_18;
```

- [ ] **Step 2: Format the repository**

Run from the flake root:

```bash
nix fmt
```

Expected: the formatter exits successfully and does not change unrelated files.

### Task 4: Verify the declarative change and hand off the remote procedure

**Files:**
- Verify: `postgres.nix`, `postgres-major-upgrade.sh`, `tests/postgres-major-upgrade-test.sh`

**Interfaces:**
- Consumes: the modified flake and the helper.
- Produces: fresh local evidence from the smoke test, `nix flake check`, and a target-specific `rbpi-nixos` build, plus a command sequence for the remote machine.

- [ ] **Step 1: Run the helper smoke test**

```bash
bash nix_modules/tests/postgres-major-upgrade-test.sh
```

Expected: exit 0.

- [ ] **Step 2: Evaluate the flake checks**

```bash
nix flake check
```

Expected: `all checks passed!`.

- [ ] **Step 3: Build the Raspberry Pi target**

```bash
nix build .#nixosConfigurations.rbpi-nixos.config.system.build.toplevel
```

Expected: exit 0 and a new system derivation containing PostgreSQL 18.

- [ ] **Step 4: Give the operator the remote sequence**

Before switching, the operator runs:

```bash
sudo nixos-rebuild build --flake /path/to/nixos-configs#rbpi-nixos
sudo /path/to/nixos-configs/nix_modules/postgres-major-upgrade.sh backup 16
```

After checking the printed backup path and stopping application writers, the operator runs:

```bash
sudo nixos-rebuild switch --flake /path/to/nixos-configs#rbpi-nixos
sudo /path/to/nixos-configs/nix_modules/postgres-major-upgrade.sh migrate 16 18 /var/backups/postgresql-major-upgrade/<timestamp>
sudo systemctl start postgresql
sudo -u postgres psql -Atc 'SELECT version();'
sudo -u postgres psql -l
sudo systemctl start pgbouncer
```

The old `/var/lib/postgresql/16` directory remains the rollback source until validation is complete. If migration fails, keep PostgreSQL stopped, restore the Nix configuration to `pkgs.postgresql_16`, rebuild/switch, and start PostgreSQL against the untouched old directory. Only after application validation should the operator run the generated `analyze_new_cluster.sh`; the old cluster must not be deleted until a separate, deliberate cleanup decision.
