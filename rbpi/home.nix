{ pkgs, ... }:

{

  imports = [
    ./../home_manager_configs/direnv.nix
    ./../home_manager_configs/git.nix
    ./../home_manager_configs/nnn.nix
    ./../home_manager_configs/tmux.nix
    ./../home_manager_configs/zoxide.nix
    ./../home_manager_configs/zsh_common.nix
  ];

  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  home.username = "liam";
  home.homeDirectory = "/home/liam";

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
    nixpkgs-fmt
  ];

}
