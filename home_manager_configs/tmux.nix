{ ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    mouse = true;
    terminal = "screen-256color";
    aggressiveResize = true;
    historyLimit = 5000;
    extraConfig = ''
      status-style bg="#ABB2BF"
      status-style fg="#282C34"
      status-left-length 50
      set-option -g pane-border-fg "#ABB2BF"
      set-option -g pane-active-border-fg "#61AFEF"
    '';
  };
}
