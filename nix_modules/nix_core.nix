{ lib, pkgs, config, ... }:

{
  options = {
    nix_core = {
      allowUnfree = lib.mkOption {
        default = false;
        type = lib.types.bool; # TODO: check this ?
      };
      autoOptimiseStore = lib.mkOption {
        default = true;
        type = lib.types.bool; # TODO: check this ?
      };
      hostPlatform = lib.mkOption { type = lib.types.str; }; # TODO: ensure this is optional and defaults to null i think (check if it has a value on nixos platform)
      permittedInsecurePackages = lib.mkOption { default = [ ]; type = lib.types.list; }; # TODO: ensure this also works and defaults and stuff
    };
  };
  config = {
    nix = {
      package = pkgs.nix;
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = config.nix_core.autoOptimiseStore;
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      };
    };

    nixpkgs.config.allowUnfree = config.nix_core.allowUnfree;
    nixpkgs.hostPlatform = config.nix_core.hostPlatform; #TODO: check if need assert here
    nixpkgs.config.permittedInsecurePackages = config.nix_core.permittedInsecurePackages;
  };
}
