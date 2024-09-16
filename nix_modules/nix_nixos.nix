{ inputs, ... }:
let
  inputNixpkgs = inputs.nixpkgs;
  linuxBase = "/etc/nixpkgs/channels";
  linuxNixpkgsPath = "${linuxBase}/nixpkgs";
in
{
  systemd.tmpfiles.rules = [
    "L+ ${linuxNixpkgsPath}     - - - - ${inputNixpkgs}"
  ];
}
