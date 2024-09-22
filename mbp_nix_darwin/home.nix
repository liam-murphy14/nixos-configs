{ pkgs, ... }:

let
  username = "liammurphy";
  homeDirectoryPath = "/Users/${username}";
in

{

  imports = [
    ./../home_manager_configs/git
    ./../home_manager_configs/neovim
    ./../home_manager_configs/python3
    ./../home_manager_configs/vscode/vsc.nix
    ./../home_manager_configs/zsh
  ];

  nix_neovim.enableCopilot = true;

  zsh_common.homeDirectoryPath = homeDirectoryPath;

  home.username = username;
  home.homeDirectory = homeDirectoryPath;

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

    # JAVA
    jdk21
  ];

}
