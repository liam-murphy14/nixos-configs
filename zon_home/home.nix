{ pkgs, lib, config, ... }:

{
  imports = [
    ./../home_manager_configs/python3
    ./../home_manager_configs/tmux.nix
    ./../home_manager_configs/zsh
  ];
  options.zon_home = {
    homeDirectoryPath = lib.mkOption { default = "/home/murplia"; type = lib.types.str; };
    extraInitExtra = lib.mkOption { default = ""; type = lib.types.str; };
    extraPreInit = lib.mkOption { default = ""; type = lib.types.str; };
  };

  config = {
    home.username = "murplia";
    home.homeDirectory = config.zon_home.homeDirectoryPath;
    home.stateVersion = "23.11";

    nix_neovim.enableZonBemol = true;

    zsh_common.homeDirectoryPath = config.zon_home.homeDirectoryPath;
    zsh_common.extraPreInit = config.zon_home.extraPreInit;
    zsh_common.extraInitExtra = ''
      export PATH=$PATH:$HOME/.toolbox/bin
      # Set up mise for runtime management
      eval "$(mise activate zsh)"
      if [ -e ${config.zon_home.homeDirectoryPath}/.brazil_completion/zsh_completion ]; then source ${config.zon_home.homeDirectoryPath}/.brazil_completion/zsh_completion; fi
      if [ -e ${config.zon_home.homeDirectoryPath}/.nix-profile/etc/profile.d/nix.sh ]; then . ${config.zon_home.homeDirectoryPath}/.nix-profile/etc/profile.d/nix.sh; fi
      export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
    '' + config.zon_home.extraInitExtra;
    zsh_common.extraShellAliases = {
      bb = "brazil-build";
      brc = "brazil-recursive-cmd";
      brca = "brazil-recursive-cmd --allPackages";
      auth = "mwinit -o -s";
    };

    home.packages = with pkgs; [
      zoxide
      ripgrep
      bat
      nerd-fonts.fira-code
      zstd
    ];

    fonts.fontconfig.enable = true;

    home.file = { };
    home.sessionVariables = { };

    programs.home-manager.enable = true;
  };
}
