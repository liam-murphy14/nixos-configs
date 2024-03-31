{ ... }:

{
  imports = [
    ./postgres.nix # module is named nix_postgres
  ];

  services.postgresql = {
    ensureDatabases = [ "housefire" ];
    ensureUsers = [
      {
        name = "housefire";
        ensureDBOwnership = true;
      }
    ];
  };

  nix_postgres = {
    extraAuthLines = ''
      local sameuser  housefire     scram-sha-256
      host  sameuser  housefire     all              scram-sha-256
    '';
    pgbouncerDatabases = {
      housefire = "host=/run/postgresql dbname=housefire user=housefire ";
    };
  };

  users.users.housefire = {
    linger = true;
    isSystemUser = true;
    group = "housefire";
  };
  users.groups.housefire = { };

  # TODO: add systemd service
}
