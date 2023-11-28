{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    mouse = true;
    terminal = "screen-256color";
  };
}
