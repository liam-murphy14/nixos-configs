{ lib, config, pkgs, ... }:

{
  options.zsh_common.homeDirectoryPath = lib.mkOption { default = "/home/liam"; type = lib.types.str; };

  config = {
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
      };
    };
  };
}
