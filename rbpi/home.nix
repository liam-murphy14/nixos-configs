{ pkgs, ... }:

let
  username = "liam";
  homeDirectory = "/home/${username}";
in
{

  imports = [
    ./../home_manager_configs/git
    ./../home_manager_configs/neovim/minimum.nix
    ./../home_manager_configs/tmux.nix
    ./../home_manager_configs/zsh
  ];

  nix_neovim.enableCopilot = true;

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
    file

    # DEV GENERAL
    ripgrep
    thefuck
    bat
    gnumake
  ];

}
