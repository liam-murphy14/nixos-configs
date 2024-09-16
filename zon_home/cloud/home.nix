{ pkgs, ... }:

let
  homeDirectoryPath = "/local/home/murplia";
in

{
  home.username = "murplia";
  home.homeDirectory = homeDirectoryPath;
  home.stateVersion = "23.11";

  imports = [
    ./../../home_manager_configs/neovim
    ./../../home_manager_configs/python3
    ./../../home_manager_configs/tmux.nix
    ./../../home_manager_configs/zsh
  ];

  zsh_common.homeDirectoryPath = homeDirectoryPath;
  zsh_common.extraInitExtra = ''
    if [ -e /home/murplia/.nix-profile/etc/profile.d/nix.sh ]; then . /home/murplia/.nix-profile/etc/profile.d/nix.sh; fi
    export PATH=$HOME/.toolbox/bin:$PATH
  '';
  zsh_common.extraShellAliases = {
    bb = "brazil-build";
    auth = "kinit && mwinit -o -s";
  };

  home.packages = with pkgs; [
    zoxide
    thefuck
    ripgrep
    bat
  ];

  home.file = { };
  home.sessionVariables = { };

  programs.home-manager.enable = true;
}
