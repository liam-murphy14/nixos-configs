{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    font = "FiraCode Nerd Font 18";
    terminal = "${pkgs.kitty}/bin/kitty";
    cycle = true;
    theme = "Arc-Dark";
  };
}
