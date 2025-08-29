{ ... }:
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    mouse = true;
    terminal = "screen-256color";
    aggressiveResize = true;
    historyLimit = 50000;
    extraConfig = ''
      set -g status-style "bg=#ABB2BF","fg=#282C34"
      set -g status-left-length 50
      set -g pane-border-style "fg=#ABB2BF"
      set -g pane-active-border-style "fg=#61AFEF"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';
  };
}
