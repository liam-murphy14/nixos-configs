# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ ... }:

{

  sops.defaultSopsFile = ./secrets/liam_rbpi_nixos.yaml;
  sops.age.keyFile = "/home/liam/.config/sops/age/keys.txt";
  sops.age.generateKey = true;
  sops.secrets.hashedPassword = {
    neededForUsers = true;
  };

  sops.secrets.housefireUserlist = {
    format = "binary";
    sopsFile = ./secrets/housefire_userlist.txt;
    owner = "pgbouncer";
    path = "/var/lib/pgbouncer/userlist.txt";
    restartUnits = [ "pgbouncer.service" ];
  };

  sops.secrets.rustyDdnsCloudflareToken = {
    format = "binary";
    sopsFile = ./secrets/rusty_ddns_cloudflare_token.txt;
    owner = "rusty-ddns";
    restartUnits = [ "rusty-ddns.service" ];
  };

}
