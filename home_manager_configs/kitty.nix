{ pkgs, ... }:

{
  programs.kitty = {

    enable = true;

    font = {
      package = pkgs.nerd-fonts.fira-code;
      name = "FiraCode Nerd Font";
      size = 14.0;
    };

    theme = "One Half Dark";

    keybindings = {
      "ctrl+shift+1" = "goto_tab 1";
      "ctrl+shift+2" = "goto_tab 2";
      "ctrl+shift+3" = "goto_tab 3";
      "ctrl+shift+4" = "goto_tab 4";
      "ctrl+shift+5" = "goto_tab 5";
      "ctrl+shift+6" = "goto_tab 6";
      "ctrl+shift+7" = "goto_tab 7";
      "ctrl+shift+8" = "goto_tab 8";
      "ctrl+shift+9" = "goto_tab 9";
    };
  };
}
