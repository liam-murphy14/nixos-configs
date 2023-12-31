{ pkgs, ... }:

let
  my-python-packages = ps: with ps; [
    ipython
    matplotlib
    pandas
    numpy
    black
  ];
  username = "liammurphy";
  homeDirectoryPath = "/Users/${username}";
in

{

  imports = [
    ./../home_manager_configs/direnv.nix
    ./../home_manager_configs/git.nix
    ./../home_manager_configs/neovim.nix
    ./../home_manager_configs/zoxide.nix
    ./../home_manager_configs/zsh_common.nix
  ];

  zsh_common.homeDirectoryPath = homeDirectoryPath;


  home.username = username;
  home.homeDirectory = homeDirectoryPath;

  home.stateVersion = "23.11";

  home.file.".ipython/profile_default/ipython_config.py".source = ./../home_manager_configs/ipython_config.py;
  home.file.".oh_my_zsh/custom/themes/custom-robbyrussell.zsh-theme".source = ./../home_manager_configs/custom-robbyrussell.zsh-theme;

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
