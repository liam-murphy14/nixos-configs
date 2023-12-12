{ pkgs, ... }:

{
  programs.zsh = {

    enable = true;
    defaultKeymap = "viins";

    initExtra = "HYPHEN_INSENSITIVE=\"true\"";

    oh-my-zsh = {
      enable = true;
      plugins = [ "docker" "vi-mode" "zoxide" "thefuck" "direnv" ];
      theme = "robbyrussell";
    };

    shellAliases = {
      cd = "z";

      cat = "bat";

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
}
