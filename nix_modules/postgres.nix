{ lib, pkgs, config, ... }:

{
  options = {
    nix_postgres = {
      ensureDatabases = lib.mkOption { default = [ ]; type = lib.types.listOf lib.types.str; };
      extraIdentLines = lib.mkOption { default = ""; type = lib.types.str; };
      extraAuthLines = lib.mkOption { default = ""; type = lib.types.str; };
    };
  };
  config = {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      ensureDatabases = config.nix_postgres.ensureDatabases;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      postgres  postgres
           # Let other names login as themselves
           alluser_map        /^(.*)$   \1
      '' + config.nix_postgres.extraIdentLines;
      authentication = pkgs.lib.mkOverride 10 (''
        #type database  DBuser  auth-method optional_ident_map
        local sameuser  all     peer        map=superuser_map
      '' + config.nix_postgres.extraAuthLines);
    };
  };
}
