{ pkgs, ... }:

{

  imports = [
    ./../home_manager_configs/chromium.nix
    ./../home_manager_configs/direnv.nix
    ./../home_manager_configs/git.nix
    ./../home_manager_configs/i3.nix
    ./../home_manager_configs/i3status.nix
    ./../home_manager_configs/kitty.nix
    ./../home_manager_configs/nnn.nix
    ./../home_manager_configs/rofi.nix
    ./../home_manager_configs/vscode.nix
    ./../home_manager_configs/zoxide.nix
    ./../home_manager_configs/zsh_common.nix
    ./../home_manager_configs/zsh_linux.nix
  ];

  xsession.enable = true;

  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  home.username = "liam";
  home.homeDirectory = "/home/liam";

  home.stateVersion = "22.05";

  home.keyboard.options = [ "ctrl:swapcaps" ];

  home.pointerCursor = {
    package = pkgs.gnome.adwaita-icon-theme;
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

    # DEV GENERAL
    ripgrep
    thefuck
    slack
    bat
    gnumake
    dbeaver

    # NODE
    yarn
    nodejs-16_x

    # JAVA
    jdk17_headless

    # RBPI
    rpi-imager

    # NIX
    nil
    nixpkgs-fmt
  ];

}
