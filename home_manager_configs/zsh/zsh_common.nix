{ lib, config, pkgs, ... }:

{
  options.zsh_common = {
    homeDirectoryPath = lib.mkOption { default = "/home/liam"; type = lib.types.str; };
    includeGuiLinuxAliases = lib.mkOption { default = false; type = lib.types.bool; };
  };

  config = {

    home.file.".oh_my_zsh/custom/themes/custom-robbyrussell.zsh-theme".source = ./custom-robbyrussell.zsh-theme;
    home.file."bin".source = ./bin;

    home.sessionPath = [
      "${config.zsh_common.homeDirectoryPath}/bin"
    ];

    programs.zsh = {

      enable = true;
      defaultKeymap = "viins";

      initExtra = "HYPHEN_INSENSITIVE=\"true\""; #TODO: fix this or add option and PR

      oh-my-zsh = {
        enable = true;
        custom = "${config.zsh_common.homeDirectoryPath}/.oh_my_zsh/custom";
        plugins = [ "docker" "vi-mode" "zoxide" "thefuck" "direnv" ];
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
        gp = "git push";
        gb = "git branch";
        gch = "git checkout --no-guess";

        avenv = "source $(find . -type d -maxdepth 1 -name \"*venv*\")/bin/activate";

        jekser = "bundle exec jekyll serve --livereload --drafts";

      } // lib.optionalAttrs config.zsh_common.includeGuiLinuxAliases {
        # only for gui linux
        autox = "xrandr --output HDMI-1 --auto --right-of eDP-1";
        open = "xdg-open";
      };
    };
  };
}
