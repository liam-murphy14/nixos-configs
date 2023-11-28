{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    customPanelNavigationAndResize = true;
    mouse = true;
    terminal = "screen-256color";
  };
}
