{ pkgs, lib, ... }:
{
  xsession.windowManager.i3 = {

    enable = true;

    config = rec {
      modifier = "Mod1";

      fonts = {
        names = [ "FiraCode Nerd Font" ];
        size = 13.0;
      };

      window.border = 2;

      bars = [{
        position = "top";
        fonts = {
          names = [ "FiraCode Nerd Font" ];
          size = 10.0;
        };
        statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-default.toml";
      }];

      keybindings = lib.mkOptionDefault {
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 4%-";
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 4%+ -l 1.0";
        "XF86MonBrightnessDown" = "exec brightnessctl set 4%-";
        "XF86MonBrightnessUp" = "exec brightnessctl set 4%+";

        "${modifier}+Return" = "exec ${pkgs.kitty}/bin/kitty";
        "${modifier}+space" = "exec ${pkgs.rofi}/bin/rofi -modi drun -show drun";
        "${modifier}+Shift+Return" = "exec ${pkgs.chromium}/bin/chromium";
        "${modifier}+Shift+n" = "exec ${pkgs.kitty}/bin/kitty -e nnn -de";

        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";

        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";

        "${modifier}+b" = "splith";
        "${modifier}+v" = "splitv";

        "${modifier}+Shift+f" = "floating toggle";

      };

      modes = lib.mkOptionDefault {
        resize = {
          "h" = "resize grow width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize shrink width 10 px or 10 ppt";
          "${modifier}+r" = "mode default";
        };
      };
    };
    extraConfig = ''
              default_border pixel 1
      	default_floating_border pixel 1
      	exec i3-msg workspace 1
      	'';
  };


}
