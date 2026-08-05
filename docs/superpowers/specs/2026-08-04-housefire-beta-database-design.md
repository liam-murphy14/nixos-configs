# Housefire Beta Database Design

**Date:** 2026-08-04

**Status:** Approved for implementation

## Goal

Provide a fully writable beta environment for the Housefire SvelteKit application while keeping the production database and Housefire scraper workload safe on the resource-constrained Raspberry Pi host.

## Context

The `rbpi-nixos` host currently runs one PostgreSQL 18 cluster and one PgBouncer instance. The production application connects to the `housefire` database as the `housefire` role. The Python scraper uploads through the Housefire HTTP API; it does not connect to PostgreSQL directly.

The SvelteKit application uses:

- `DB_URL` for runtime Prisma traffic through PgBouncer;
- `DB_URL_DIRECT` for Prisma CLI operations such as migrations; and
- `SELF_API_KEY` to protect its API routes.

The beta application must be independently writable. Beta writes must not modify production records, and refreshing beta from production must be explicit because refresh destroys existing beta data.

## Options considered

### Same PostgreSQL cluster with a separate database and role — selected

Create `housefire_beta` and a dedicated `housefire_beta` PostgreSQL role in the existing cluster. Add a PgBouncer mapping for the beta database and use a small connection limit. Provide an explicit refresh helper that streams a production dump into a recreated beta database.

This adds no second PostgreSQL postmaster or idle service memory, leaves production online during the dump, and gives the beta application database-level write isolation. The trade-off is logical rather than process-level isolation, plus temporary I/O and CPU during refresh.

### Separate PostgreSQL cluster on the Raspberry Pi

Run a second cluster with its own data directory, port, and service settings. This provides stronger process and configuration isolation, but duplicates PostgreSQL memory, background processes, upgrade work, and backup responsibilities. It is not appropriate for the host’s resource budget.

### External managed PostgreSQL or a second host

Move beta to a managed database or another small host. This provides the strongest resource and failure isolation, but adds recurring cost, TLS/network configuration, and another system to maintain. It is a future migration path if beta traffic becomes materially larger than a test workload.

## Architecture

### NixOS module

Add an opt-in `nix_modules/housefire_beta.nix` module and import it only in the `rbpi-nixos` output. The module will:

1. ensure the `housefire_beta` database exists;
2. ensure the `housefire_beta` login role exists and owns that database;
3. limit the role to five PostgreSQL connections;
4. add `local` and TCP `pg_hba` rules restricted to the matching beta database and role; and
5. add a PgBouncer database mapping for `housefire_beta` through `/run/postgresql`, with a small pool.

The existing production `housefire` database, role, authentication rules, PgBouncer mapping, and systemd ticker services remain unchanged.

The beta role’s password will be represented by a SCRAM verifier in the existing SOPS-managed PgBouncer userlist. The existing userlist secret will be readable by both PostgreSQL credential synchronization and PgBouncer. A oneshot systemd unit will read only the beta verifier, apply it to the PostgreSQL role, and never print the value. Secret changes will restart the synchronization unit and PgBouncer.

### Refresh helper

Install a guarded `housefire-beta-db` command from the beta module. Its supported operation is:

```text
housefire-beta-db refresh --confirm
```

The command must:

1. require root privileges and the explicit `--confirm` flag;
2. take a consistent `pg_dump` of the production `housefire` database over the local PostgreSQL socket;
3. drop only `housefire_beta`, forcibly terminating beta connections because refresh is destructive;
4. recreate `housefire_beta` owned by `housefire_beta`;
5. restore the dump without production ownership or ACL statements while executing as the beta role, so restored objects are writable by beta; and
6. run `ANALYZE` against the refreshed database.

The dump and restore will stream through a pipeline rather than writing a second full database dump to disk. This minimizes temporary storage use. The helper will use `ON_ERROR_STOP` and fail closed on pipeline errors. Refresh is not scheduled automatically; beta remains writable between explicit refreshes.

### Application wiring

The beta SvelteKit deployment will use separate environment values:

```text
DB_URL=postgresql://housefire_beta:<beta-password>@rbpi.liammurphydev.com:6432/housefire_beta
DB_URL_DIRECT=postgresql://housefire_beta:<beta-password>@rbpi.liammurphydev.com:5432/housefire_beta
SELF_API_KEY=<beta-only-api-key>
```

The beta deployment must apply tracked Prisma migrations through `DB_URL_DIRECT` before serving code that requires a newer schema. Runtime requests continue through `DB_URL` and PgBouncer.

The Python scraper can write to beta by using a separate private CLI configuration with `DEPLOY_ENV` set for beta, a beta API key, and the beta deployment’s `/api/` base URL. Existing production systemd ticker services will continue using their existing configuration and will not be retargeted.

No additional firewall ports are required because the host already exposes PostgreSQL 5432 and PgBouncer 6432. The beta role and database name must be used together; no beta credential may be granted ownership or access to the production database.

## Data flow

```text
Production Housefire app
  -> DB_URL -> PgBouncer:6432 -> housefire database -> housefire role

Beta Housefire app
  -> DB_URL -> PgBouncer:6432 -> housefire_beta database -> housefire_beta role

Beta Prisma CLI
  -> DB_URL_DIRECT -> PostgreSQL:5432 -> housefire_beta database

Beta refresh
  -> pg_dump housefire | psql --role=housefire_beta housefire_beta
```

The production scraper continues uploading to the production API. A beta scraper run points at the beta API and therefore writes only to beta through the beta API’s database connection.

## Failure handling and safety

- The refresh command refuses to run without `--confirm` and names the beta database in its user-facing error messages.
- It never drops or alters the production database.
- A failed refresh exits nonzero and leaves beta unavailable or incomplete; rerunning the explicit refresh is the recovery path. Production is unaffected.
- Credential synchronization fails if the beta userlist entry is absent or malformed and does not log the verifier.
- The beta PostgreSQL role has no production database ownership or grants.
- Beta API credentials and database URLs remain deployment secrets and are documented only as variable names.

## Verification

The implementation will be checked at four levels:

1. shell-level tests for refresh confirmation, database targeting, streaming restore, and secret non-disclosure;
2. `nix fmt` and `nix flake check` for module evaluation and formatting;
3. `nixos-rebuild build --flake .#rbpi-nixos` for the target system derivation; and
4. manual host verification after activation: beta database/role existence, PgBouncer connectivity, beta-only writes, production data unchanged, and a beta application migration/read/write smoke test.

The manual refresh and beta deployment steps will be documented without including any secret values.
