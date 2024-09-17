{ lib, pkgs, config, inputs, ... }:

# TODO: find better way to share these
# let
#   inputNixpkgs = inputs.nixpkgs;
# in
{
  options = {
    nix_core = {
      allowUnfree = lib.mkOption {
        default = false;
        type = lib.types.bool;
      };
      autoOptimiseStore = lib.mkOption {
        default = true;
        type = lib.types.bool;
      };
      hostPlatform = lib.mkOption { type = lib.types.nullOr lib.types.str; };
      permittedInsecurePackages = lib.mkOption { default = [ ]; type = lib.types.listOf lib.types.package; };
      # nixpkgsPath = lib.mkOption {
      #   default = "/etc/nixpkgs/channels/nixpkgs";
      #   type = lib.types.str;
      # };
    };
  };
  config = {
    nix = {
      package = pkgs.nix;
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = config.nix_core.autoOptimiseStore;
      };
      # registry.nixpkgs.flake = inputNixpkgs;
      # nixPath = [
      #   "nixpkgs=flake:nixpkgs"
      #   "darwin-config=/Users/liammurphy/.nixpkgs/darwin-configuration.nix"
      # ];
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      };
      channel.enable = false;
    };

    nixpkgs.config.allowUnfree = config.nix_core.allowUnfree;
    nixpkgs.hostPlatform = config.nix_core.hostPlatform; #TODO: check if need assert here with blank
    nixpkgs.config.permittedInsecurePackages = config.nix_core.permittedInsecurePackages;
  };
}
