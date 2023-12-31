{ pkgs, ... }:

let
  username = "liam";
  homeDirectory = "/home/${username}";
in
{

  imports = [
    ./../home_manager_configs/git.nix
    ./../home_manager_configs/nnn.nix
    ./../home_manager_configs/tmux.nix
    ./../home_manager_configs/zsh
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;

  zsh_common.homeDirectoryPath = homeDirectory;

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    # CORE
    zip
    unzip
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
