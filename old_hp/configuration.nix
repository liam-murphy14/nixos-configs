# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, config, lib, ... }:

{
  # CORE
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./secrets.nix
      ./../nix_modules/nix_core.nix
      ./../nix_modules/nix_nixos.nix
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.cleanOnBoot = true;
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware.pulseaudio.enable = true;

  # NETWORK
  networking.hostName = "old-hp-nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  services.resolved = {
    enable = true;
    fallbackDns = [
      "8.8.8.8"
    ];
  };

  # NIX
  nix_core.allowUnfree = true;
  nix_core.hostPlatform = "x86_64-linux";

  # INTERNATIONALIZATION
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  # FONTS
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];
  };

  # SERVICES
  services = {
    xserver = {
      enable = true;
      layout = "us";

      libinput = {
        enable = true;
        touchpad = {
          accelSpeed = "0.3";
          naturalScrolling = true;
          clickMethod = "clickfinger";
          tapping = true;
        };
      };
      displayManager = {
        lightdm = { enable = true; };
      };
      desktopManager.session = [
        {
          # fake session to trick lightdm
          manage = "window";
          name = "home-manager";
          start = "";
        }
      ];
    };
  };

  # STEAM
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];

  virtualisation.docker.enable = true;
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  services.printing.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # USERS
  users.mutableUsers = false; # no mutable users
  users.users.liam = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.hashedPassword.path;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # PACKAGES
  environment.systemPackages = with pkgs; [
    neovim
  ];
  environment.variables.EDITOR = "nvim";
  environment.pathsToLink = [ "/share/zsh" ];


  system.copySystemConfiguration = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}

