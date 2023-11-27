{ pkgs, ... }:

{
  programs.zsh.shellAliases.autox = "xrandr --output HDMI-1 --auto --right-of eDP-1";
  programs.zsh.shellAliases.open = "xdg-open";
}
