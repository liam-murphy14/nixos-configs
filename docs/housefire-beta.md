# Housefire beta environment

Housefire beta shares the PostgreSQL 18 cluster with production, but uses a
separate writable database and login role. The production database, role,
pooling entry, and ticker services remain unchanged.

- Database: `housefire_beta`
- Role: `housefire_beta`
- Runtime connection: PgBouncer on port `6432`
- Prisma and migration connection: PostgreSQL directly on port `5432`

## Activate the infrastructure

Run these commands from the NixOS configuration repository. Build and check
before switching the Raspberry Pi:

```sh
nix fmt
nix flake check
sudo nixos-rebuild build --flake .#rbpi-nixos
sudo nixos-rebuild switch --flake .#rbpi-nixos
```

Activation creates the beta database and role wiring but does not create a
usable application password. Complete credential bootstrap before starting
the beta application.

## Bootstrap the beta credential

Set the role password interactively so it is not placed in shell history:

```sh
sudo -u postgres psql --no-psqlrc postgres
```

At the `psql` prompt, use PostgreSQL’s password prompt, then exit:

```sql
\password housefire_beta
\q
```

Retrieve the resulting verifier only into a temporary mode-600 file for
immediate encrypted-userlist editing. This command redirects the value; it
does not print it:

```sh
verifier_file="$(mktemp)"
chmod 600 "$verifier_file"
sudo -u postgres psql --no-psqlrc -Atqc \
  "SELECT rolpassword FROM pg_authid WHERE rolname = 'housefire_beta';" \
  > "$verifier_file"
```

Open the encrypted userlist with `sops rbpi/secrets/housefire_userlist.txt`
and add one `housefire_beta` entry in the same quoted userlist format as the
existing entry. Transfer the verifier from the temporary file without
printing it, save the encrypted file, then remove the temporary file:

```sh
rm -- "$verifier_file"
```

Never put the password or verifier in this repository, an unencrypted file,
shell history, command arguments, logs, terminal output, commit messages, or
documentation. If SOPS does not restart the services after the encrypted
secret changes, restart them explicitly:

```sh
sudo systemctl restart housefire-beta-sync-credentials.service
sudo systemctl restart pgbouncer.service
```

Check service state without displaying credentials:

```sh
systemctl is-active postgresql pgbouncer
sudo systemctl is-active housefire-beta-sync-credentials.service
```

## Refresh beta from production

This operation is destructive to beta. It drops and recreates only
`housefire_beta`, streams a consistent production dump into it, restores as
`housefire_beta`, and analyzes the result. It does not modify production.

Confirm that beta data may be discarded before running the exact
confirmation-gated command:

```sh
sudo housefire-beta-db refresh --confirm
```

Do not run this command while beta-only data must be preserved. Never replace
the command with an ad-hoc `DROP DATABASE`, point it at `housefire`, or run it
against a production deployment.

## Configure the beta SvelteKit deployment

Configure these values in the beta deployment’s private secret store. Keep
the beta database, role, password, and API key separate from production. Use
PgBouncer for runtime traffic and direct PostgreSQL for Prisma CLI and
migration traffic:

```text
DB_URL=<beta-runtime-url-for-housefire_beta-via-port-6432>
DB_URL_DIRECT=<beta-migration-url-for-housefire_beta-via-port-5432>
SELF_API_KEY=<beta-only-api-key>
```

In the deployment secret store, make `DB_URL` use the `housefire_beta` role
and database through PgBouncer on `6432`, and make `DB_URL_DIRECT` use the
same beta role and database through PostgreSQL on `5432`. Replace only the
angle-bracketed placeholders in the deployment system; do not replace them
in this repository or commit real values here. URL-encode password
characters when required by the connection-string parser.

Apply tracked Prisma migrations through the direct URL before deploying code
that requires a newer schema:

```sh
npm run db:migrate
```

Keep the beta `SELF_API_KEY` distinct from the production API key, and ensure
the beta application is pointed at the beta URLs before performing any write
smoke test.

## Point the Python scraper at beta

Create a private Housefire CLI config containing the beta API base URL ending
in `/api/`, the beta API key, the beta deployment environment, and private
temporary and log directories. From the Python scraper repository, pass that
config explicitly:

```sh
cd /path/to/python_serverless_housefire
nix run . -- --config-path /private/path/housefire-beta.ini run-data-pipeline pld
```

Do not change the production `~/.config/housefire/default.ini` or existing
production systemd ticker services. Do not point the beta scraper at a
production API URL or use a production API key.

## Verify isolation

Run these checks on the Raspberry Pi without printing credentials:

```sh
sudo -u postgres psql --no-psqlrc -Atqc \
  "SELECT datname FROM pg_database WHERE datname IN ('housefire', 'housefire_beta') ORDER BY datname;"
sudo -u postgres psql --no-psqlrc -Atqc \
  "SELECT rolname FROM pg_roles WHERE rolname IN ('housefire', 'housefire_beta') ORDER BY rolname;"
sudo systemctl is-active postgresql pgbouncer housefire-beta-sync-credentials.service
```

The results must show both production and beta names, with the beta
application using only the beta role/database pair. Then perform a beta API
create/update/delete smoke test using the beta API key and verify through the
beta direct URL that it reaches `housefire_beta`. Confirm that a beta-only
record is absent from the production application path.

Production-safety rules:

- Never run the beta refresh command against production or alter production
  configuration to make beta work.
- Never reuse production database credentials or `SELF_API_KEY` for beta.
- Never change the production scraper config or ticker services as part of
  beta testing.
- Treat refresh as data loss for beta and obtain explicit operator
  confirmation before every run.
