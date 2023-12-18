{ pkgs, ... }:

{

  imports = [
    ./../home_manager_configs/direnv.nix
    ./../home_manager_configs/git.nix
    ./../home_manager_configs/zoxide.nix
    ./../home_manager_configs/zsh_common.nix
  ];

  home.username = "liammurphy";
  home.homeDirectory = "/Users/liammurphy";

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    # CORE
    age
    sops

    # DEV GENERAL
    ripgrep
    thefuck
    bat
    gnumake

    # NIX
    nil
  ];

}