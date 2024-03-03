{ ... }:

{
  imports = [
    ./postgres.nix # module is named nix_postgres
  ];

  nix_postgres.ensureDatabases = [ "housefire_core" ];
  nix_postgres.extraIdentLines = ''
      housefire_map      housefire  housefire_core
  '';

  users.users.housefire = {
    linger = true;
    isSystemUser = true;
    group = "housefire";
  };
  users.groups.housefire = {};

  # TODO: add systemd service
}
