# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, config, ... }:

{
  # CORE
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./secrets.nix
      ./../nix_modules/nix_core.nix
      ./../nix_modules/nix_nixos.nix
      ./../nix_modules/housefire.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  hardware.pulseaudio.enable = true;

  # NETWORK
  networking = {
    hostName = "rbpi-nixos"; # Define your hostname.
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 5432 6432 8245 ];
      allowedUDPPorts = [ 5353 8245 ];
    };
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
    settings.GatewayPorts = "yes";
  };

  services.resolved = {
    enable = true;
    fallbackDns = [
      "8.8.8.8"
    ];
  };

  # NIX
  nix_core.allowUnfree = true;
  nix_core.hostPlatform = "aarch64-linux";
  # nix_core.nixpkgsPath = "/etc/nixpkgs/channels/nixpkgs";

  # INTERNATIONALIZATION
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };

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

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCexrVowwSF16fESmeH+7da4dQR5Xg6EO4O4iE6Zqo liam@liam-nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJE5qK0Ec1oNs+5WdVf9B00MoZP647ZGHxkxbR3BrxSH liammurphy@Liams-MBP-10.domain"
    ];
  };

  # PACKAGES
  environment.systemPackages = with pkgs; [
    neovim
    noip
  ];
  environment.variables.EDITOR = "nvim";
  environment.pathsToLink = [ "/share/zsh" ];


  system.copySystemConfiguration = false;

  # CUSTOM NOIP SERVICE

  systemd.services.noipDuc = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "auditd.service" "sops-nix.service" ];
    description = "Start the noip dynamic update client";
    serviceConfig = {
      # TODO: make this less bad...
      # LoadCredential = [
      #   ''noIpEmail:${config.sops.secrets.noIpEmail.path}''
      #   ''noIpPassword:${config.sops.secrets.noIpPassword.path}''
      # ];
      # ExecStart = ''export NOIPEMAIL=$(cat ${config.sops.secrets.noIpEmail.path}) NOIPPASSWORD=$(cat ${config.sops.secrets.noIpPassword.path}) ${pkgs.noip}/bin/noip2 -u $NOIPEMAIL -p $NOIPPASSWORD -Y'';
      ExecStart = ''${pkgs.noip}/bin/noip2 -c /home/liam/noip/CONFIG'';
      Type = "forking";
      User = "liam";
      Restart = "on-failure";

    };
  };
}

