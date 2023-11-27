# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, config, ... }:

{
  # CORE
  imports =
    [
      # Include the results of the hardware scan.
      # ./hardware-configuration.nix
      # ./secrets.nix
    ];

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # NETWORK
  networking = {
    hostName = "rbpi-nixos"; # Define your hostname.
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  services.resolved = {
    enable = true;
    fallbackDns = [
      "8.8.8.8"
    ];
  };

  # NIX
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
    '';
  };
  nixpkgs.config.allowUnfreePredicate = (pkg: true);

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

  programs.dconf.enable = true;
  programs.zsh.enable = true;
  services.printing.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # USERS
  users.mutableUsers = false; # no mutable users
  users.users.liam = {
    isNormalUser = true;
    # hashedPasswordFile = config.sops.secrets.hashedPassword.path;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCexrVowwSF16fESmeH+7da4dQR5Xg6EO4O4iE6Zqo liam@liam-nixos"
    ];
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

