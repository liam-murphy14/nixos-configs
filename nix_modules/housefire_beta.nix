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
    pgbouncerDatabases.housefire_beta = "host=/run/postgresql dbname=housefire_beta user=housefire_beta pool_size=5 ";
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
