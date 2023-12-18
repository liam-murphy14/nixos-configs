{ pkgs, ... }:

let
  my-python-packages = ps: with ps; [
    ipython
    matplotlib
    pandas
    numpy
    black
  ];
in

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

  home.file.".ipython/profile_default/ipython_config.py".source = ./../home_manager_configs/ipython_config.py;

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

    # PYTHON 
    (python3.withPackages my-python-packages)

    # JAVA
    jdk21
  ];

}
