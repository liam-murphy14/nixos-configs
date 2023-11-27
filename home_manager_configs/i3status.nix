{ pkgs, ... }:
{
  programs.i3status-rust = {
    enable = true;
    bars = {
      default = {
        theme = "modern";
        icons = "material-nf";
        blocks = [
          {
            block = "memory";
            interval = 5;
            format = " $icon $mem_total_used_percents  $icon_swap $swap_used_percents ";
          }
          {
            block = "cpu";
            interval = 5;
            format = " $icon $utilization ";
            format_alt = " $icon $barchart ";
          }
          {
            block = "net";
            format = " $icon $signal_strength $ssid ";
            format_alt = " $icon $ip ";
          }
          {
            block = "sound";
            format = " $icon $volume ";
          }
          {
            block = "battery";
            format = " $icon $percentage ";
            full_format = " $icon $percentage ";
            empty_format = " $icon $percentage ";
            not_charging_format = " $icon $percentage ";
          }
          {
            block = "time";
            interval = 60;
            format = " $timestamp.datetime(f:'%a %m/%d %R') ";
          }
        ];
      };
    };
  };
}
