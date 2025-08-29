{ lib, config, ... }:

{
  options.zsh_common = {
    homeDirectoryPath = lib.mkOption { default = "/home/liam"; type = lib.types.str; };
    includeGuiLinuxAliases = lib.mkOption { default = false; type = lib.types.bool; };
    extraPreInit = lib.mkOption { default = ""; type = lib.types.str; };
    extraInitExtra = lib.mkOption { default = ""; type = lib.types.str; };
    extraShellAliases = lib.mkOption { default = { }; type = lib.types.attrsOf lib.types.str; };
  };

  config = {

    home.file.".oh_my_zsh/custom/themes/custom-robbyrussell.zsh-theme".source = ./custom-robbyrussell.zsh-theme;

    programs.zsh = {

      enable = true;
      defaultKeymap = "viins";

      # TODO: fix HYPHEN_INSENSITIVE option or add option and PR
      initContent = config.zsh_common.extraPreInit + ''
        HYPHEN_INSENSITIVE="true"
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
      '' + config.zsh_common.extraInitExtra;

      oh-my-zsh = {
        enable = true;
        custom = "${config.zsh_common.homeDirectoryPath}/.oh_my_zsh/custom";
        plugins = [ "vi-mode" "zoxide" "direnv" ];
        theme = "custom-robbyrussell";
      };

      shellAliases = {
        cd = "z";

        cat = "bat";

        l = "ls -lah --color=auto";
        la = "ls -lAh --color=auto";
        ll = "ls -lh --color=auto";
        ls = "ls -G --color=auto";
        lsa = "ls -lah --color=auto";

        # git aliases
        ga = "git add";
        gc = "git commit -m";
        gca = "git commit --amend";
        gp = "git push";
        gb = "git branch";
        gch = "git checkout --no-guess";

        avenv = "source $(find . -type d -maxdepth 1 -name \"*venv*\")/bin/activate";

        jekser = "bundle exec jekyll serve --livereload --drafts";

      } // lib.optionalAttrs config.zsh_common.includeGuiLinuxAliases {
        # only for gui linux
        autox = "xrandr --output HDMI-1 --auto --right-of eDP-1";
        open = "xdg-open";
      } // config.zsh_common.extraShellAliases;
    };
  };
}
