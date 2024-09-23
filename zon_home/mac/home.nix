{ pkgs, ... }:

let
  homeDirectoryPath = "/Users/murplia";
in

{
  home.username = "murplia";
  home.homeDirectory = homeDirectoryPath;
  home.stateVersion = "23.11";

  imports = [
    ./../../home_manager_configs/neovim
    ./../../home_manager_configs/python3
    ./../../home_manager_configs/zsh
  ];

  zsh_common.homeDirectoryPath = homeDirectoryPath;
  zsh_common.extraInitExtra = ''
    if [ -e /home/murplia/.nix-profile/etc/profile.d/nix.sh ]; then . /home/murplia/.nix-profile/etc/profile.d/nix.sh; fi
    export PATH=$HOME/.toolbox/bin:$PATH
    eval "$(/usr/local/bin/brew shellenv)"
    source /Users/murplia/.brazil_completion/zsh_completion
  '';
  zsh_common.extraShellAliases = {
    bb = "brazil-build";
  };

  home.packages = with pkgs; [
    zoxide
    thefuck
    ripgrep
    bat
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];

  fonts.fontconfig.enable = true;

  home.file = { };
  home.sessionVariables = { };

  programs.home-manager.enable = true;
}
