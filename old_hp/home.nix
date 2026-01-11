{ pkgs, ... }:

let
  username = "liam";
  homeDirectory = "/home/${username}";
in
{

  imports = [
    ./../home_manager_configs/chromium.nix
    ./../home_manager_configs/git
    ./../home_manager_configs/i3.nix
    ./../home_manager_configs/i3status.nix
    ./../home_manager_configs/kitty
    ./../home_manager_configs/neovim
    ./../home_manager_configs/nnn.nix
    ./../home_manager_configs/python3
    ./../home_manager_configs/rofi.nix
    ./../home_manager_configs/vscode
    ./../home_manager_configs/zsh
  ];

  nix_neovim.enableCopilot = true;

  xsession.enable = true;

  home.username = username;
  home.homeDirectory = homeDirectory;

  zsh_common.homeDirectoryPath = homeDirectory;
  zsh_common.includeGuiLinuxAliases = true;

  home.stateVersion = "22.05";

  home.keyboard.options = [ "ctrl:swapcaps" ];

  home.pointerCursor = {
    package = pkgs.adwaita-icon-theme;
    gtk.enable = true;
    x11.enable = true;
    name = "Adwaita";
    size = 32;
  };

  home.packages = with pkgs; [
    # CORE
    brightnessctl
    zip
    unzip
    age
    sops
    xclip
    file
    gparted

    # DEV GENERAL
    ripgrep
    slack
    bat
    gnumake

    # JAVA
    jdk21

    # RBPI
    rpi-imager
  ];

}
