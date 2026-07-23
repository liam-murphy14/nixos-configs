#!/usr/bin/env bash
set -Eeuo pipefail

readonly BACKUP_ROOT="/var/backups/postgresql-major-upgrade"
readonly POSTGRES_DATA_ROOT="/var/lib/postgresql"
readonly CURRENT_SYSTEM_BIN="/run/current-system/sw/bin"

usage() {
  cat <<'EOF'
Usage:
  postgres-major-upgrade.sh backup OLD_MAJOR
  postgres-major-upgrade.sh migrate OLD_MAJOR NEW_MAJOR BACKUP_DIR

Run `backup` while the old PostgreSQL cluster is still serving traffic, before
deploying the new NixOS configuration. It creates a complete pg_dumpall backup
under /var/backups/postgresql-major-upgrade and prints the directory to use.

Run `migrate` after the new NixOS configuration is active. It starts the new
service once, stops PostgreSQL and PgBouncer, preserves the old cluster, moves
the automatically initialized new cluster aside, recreates it with matching
checksum settings (including --no-data-checksums for PostgreSQL 18 upgrades),
and runs pg_upgrade in copy mode.

The application services that write to PostgreSQL must be stopped by the
operator before `migrate` is run. The old data directory is never removed.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

timestamp() {
  date -u '+%Y%m%dT%H%M%SZ'
}

require_root() {
  [[ "$(id -u)" -eq 0 ]] || die 'run this command with sudo or as root'
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_major() {
  [[ "$1" =~ ^[0-9]+$ ]] || die "PostgreSQL major must be an integer: $1"
}

as_postgres() {
  sudo -u postgres -- "$@"
}

checksum_version() {
  local pg_bin="$1"
  local data_dir="$2"

  as_postgres "$pg_bin/pg_controldata" "$data_dir" \
    | awk -F: '/Data page checksum version/ { gsub(/^[[:space:]]+/, "", $2); print $2; exit }'
}

pg_major_from_bin() {
  local pg_bin="$1"
  local version

  version="$("$pg_bin/pg_upgrade" --version | awk '{ print $NF }')"
  printf '%s\n' "${version%%.*}"
}

backup_cluster() {
  local old_major="$1"
  local psql_bin
  local pg_dumpall_bin
  local server_version
  local server_major
  local backup_dir
  local dump_file
  local partial_file

  require_root
  require_command sudo
  require_command systemctl
  require_command date
  require_command install
  require_command mv
  require_command awk
  require_major "$old_major"

  systemctl is-active --quiet postgresql \
    || die 'postgresql.service must be active while creating the logical backup'

  psql_bin="$(command -v psql)"
  pg_dumpall_bin="$(command -v pg_dumpall)"
  server_version="$(as_postgres "$psql_bin" --no-psqlrc -Atqc 'SHOW server_version;')"
  server_major="${server_version%%.*}"
  [[ "$server_major" == "$old_major" ]] \
    || die "active PostgreSQL is $server_version, not major $old_major"

  backup_dir="$BACKUP_ROOT/$(timestamp)-postgresql-$old_major"
  dump_file="$backup_dir/postgresql-$old_major-all.sql"
  partial_file="$dump_file.partial"
  install -d -o root -g root -m 700 "$backup_dir"
  [[ ! -e "$dump_file" && ! -e "$partial_file" ]] \
    || die "backup output already exists: $dump_file"

  printf 'Creating complete logical backup at %s\n' "$dump_file"
  install -o root -g root -m 600 /dev/null "$partial_file"
  as_postgres "$pg_dumpall_bin" --quote-all-identifiers >"$partial_file"
  [[ -s "$partial_file" ]] || die "backup file is empty: $partial_file"
  mv -- "$partial_file" "$dump_file"

  printf '\nBackup complete. Keep this directory until the upgraded cluster has been validated:\n%s\n' "$backup_dir"
}

migrate_cluster() {
  local old_major="$1"
  local new_major="$2"
  local backup_dir="$3"
  local old_data_dir="$POSTGRES_DATA_ROOT/$old_major"
  local new_data_dir="$POSTGRES_DATA_ROOT/$new_major"
  local backup_file="$backup_dir/postgresql-$old_major-all.sql"
  local old_store_path
  local old_bin
  local new_bin="$CURRENT_SYSTEM_BIN"
  local old_package_major
  local new_package_major
  local old_checksum
  local new_checksum
  local checksum_flag
  local stamp
  local preserved_new_dir
  local work_dir
  local confirmation

  require_root
  require_command sudo
  require_command systemctl
  require_command nix
  require_command date
  require_command install
  require_command mv
  require_major "$old_major"
  require_major "$new_major"
  [[ "$old_major" != "$new_major" ]] || die 'old and new PostgreSQL majors must differ'
  [[ -s "$backup_file" ]] || die "complete backup not found or empty: $backup_file"
  [[ -d "$old_data_dir" ]] || die "old data directory not found: $old_data_dir"
  [[ ! -L "$old_data_dir" ]] || die "old data directory must not be a symlink: $old_data_dir"

  [[ -x "$new_bin/pg_upgrade" ]] \
    || die "new PostgreSQL binaries are not in $new_bin; activate the PostgreSQL $new_major NixOS configuration first"
  new_package_major="$(pg_major_from_bin "$new_bin")"
  [[ "$new_package_major" == "$new_major" ]] \
    || die "current system PostgreSQL is major $new_package_major, not $new_major"

  printf 'Build the old PostgreSQL %s client binaries from nixpkgs...\n' "$old_major"
  old_store_path="$(nix build --no-link --print-out-paths "nixpkgs#postgresql_${old_major}.out")"
  old_bin="$old_store_path/bin"
  [[ -x "$old_bin/pg_upgrade" ]] || die "old pg_upgrade binaries not found in $old_bin"
  old_package_major="$(pg_major_from_bin "$old_bin")"
  [[ "$old_package_major" == "$old_major" ]] \
    || die "resolved old PostgreSQL package is major $old_package_major, not $old_major"

  cat <<EOF

Before continuing, stop every application service that can write to PostgreSQL.
This helper will stop pgbouncer and postgresql, but it cannot know all of the
application services on this host.

Old data directory (preserved): $old_data_dir
New data directory (recreated): $new_data_dir
Logical backup: $backup_file
EOF
  read -r -p "Type POSTGRES-MIGRATE to continue: " confirmation
  [[ "$confirmation" == 'POSTGRES-MIGRATE' ]] || die 'migration not confirmed'

  printf 'Stopping PgBouncer before starting the new cluster...\n'
  systemctl stop pgbouncer

  if ! systemctl is-active --quiet postgresql; then
    printf 'Starting PostgreSQL once so NixOS initializes the new cluster...\n'
    systemctl start postgresql
  fi
  systemctl is-active --quiet postgresql \
    || die 'postgresql.service did not start successfully; inspect journalctl -u postgresql'

  new_package_major="$(as_postgres "$new_bin/psql" --no-psqlrc -Atqc 'SHOW server_version;')"
  [[ "${new_package_major%%.*}" == "$new_major" ]] \
    || die "running PostgreSQL is $new_package_major, not major $new_major"

  printf 'Stopping PostgreSQL before pg_upgrade...\n'
  systemctl stop postgresql
  systemctl is-active --quiet postgresql && die 'postgresql.service is still active'

  [[ -d "$new_data_dir" ]] || die "new data directory was not initialized: $new_data_dir"
  [[ ! -L "$new_data_dir" ]] || die "new data directory must not be a symlink: $new_data_dir"

  old_checksum="$(checksum_version "$old_bin" "$old_data_dir")"
  [[ "$old_checksum" == 0 || "$old_checksum" == 1 ]] \
    || die "could not determine old cluster checksum version: $old_checksum"

  if [[ "$old_checksum" == 0 ]]; then
    checksum_flag='--no-data-checksums'
  else
    checksum_flag='--data-checksums'
  fi

  stamp="$(timestamp)"
  preserved_new_dir="$POSTGRES_DATA_ROOT/${new_major}.pre-pg-upgrade-$stamp"
  [[ ! -e "$preserved_new_dir" ]] || die "preservation path already exists: $preserved_new_dir"
  printf 'Preserving the automatically initialized new cluster at %s\n' "$preserved_new_dir"
  mv -- "$new_data_dir" "$preserved_new_dir"

  printf 'Initializing a clean PostgreSQL %s cluster with %s...\n' "$new_major" "$checksum_flag"
  as_postgres "$new_bin/initdb" --pgdata="$new_data_dir" "$checksum_flag"
  new_checksum="$(checksum_version "$new_bin" "$new_data_dir")"
  [[ "$new_checksum" == "$old_checksum" ]] \
    || die "new cluster checksum version $new_checksum does not match old version $old_checksum"

  work_dir="$POSTGRES_DATA_ROOT/pg-upgrade-$old_major-to-$new_major-$stamp"
  install -d -o postgres -g postgres -m 700 "$work_dir"
  cd "$work_dir"

  printf 'Running pg_upgrade --check...\n'
  as_postgres "$new_bin/pg_upgrade" \
    -b "$old_bin" \
    -B "$new_bin" \
    -d "$old_data_dir" \
    -D "$new_data_dir" \
    --check

  printf 'Running pg_upgrade in copy mode...\n'
  as_postgres "$new_bin/pg_upgrade" \
    -b "$old_bin" \
    -B "$new_bin" \
    -d "$old_data_dir" \
    -D "$new_data_dir"

  cat <<EOF

pg_upgrade completed.

Old cluster (do not delete yet): $old_data_dir
Preserved pre-upgrade new cluster: $preserved_new_dir
pg_upgrade work directory: $work_dir
Logical backup: $backup_file

Validate and start the new service:
  systemctl start postgresql
  sudo -u postgres $new_bin/psql --no-psqlrc -Atc 'SELECT version();'
  sudo -u postgres $new_bin/psql --no-psqlrc -l
  systemctl start pgbouncer

After application validation, refresh planner statistics with:
  sudo -u postgres $work_dir/analyze_new_cluster.sh

Do not run delete_old_cluster.sh until the new service and every application
have been validated and the logical backup has been tested or retained.
EOF
}

main() {
  case "${1:-}" in
    --help|-h)
      usage
      ;;
    backup)
      [[ $# -eq 2 ]] || die 'usage: postgres-major-upgrade.sh backup OLD_MAJOR'
      backup_cluster "$2"
      ;;
    migrate)
      [[ $# -eq 4 ]] || die 'usage: postgres-major-upgrade.sh migrate OLD_MAJOR NEW_MAJOR BACKUP_DIR'
      migrate_cluster "$2" "$3" "$4"
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
