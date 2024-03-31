{ lib, pkgs, config, ... }:

{
  options = {
    nix_postgres = {
      extraIdentLines = lib.mkOption { default = ""; type = lib.types.str; };
      extraAuthLines = lib.mkOption { default = ""; type = lib.types.str; };
      pgbouncerDatabases = lib.mkOption { default = { }; type = lib.types.attrsOf lib.types.str; };
    };
  };
  config = {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      postgres  postgres
           # Let other names login as themselves
           # superuser_map        /^(.*)$   \1
      '' + config.nix_postgres.extraIdentLines;
      authentication = pkgs.lib.mkOverride 10 (''
        #type database  DBuser        auth-method    optional_ident_map
        local sameuser  postgres      peer           map=superuser_map
      '' + config.nix_postgres.extraAuthLines);

      enableTCPIP = true;
    };

    services.pgbouncer = {
      enable = true;
      databases = config.nix_postgres.pgbouncerDatabases;
      authType = "scram-sha-256";
      authFile = "/tmp/pgbouncer/userlist.txt"; # TODO: change to be sops generated
      listenAddress = "*";
      listenPort = 6432;
    };
  };
}
