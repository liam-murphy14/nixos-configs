{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      {
        # ublock origin
        id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      }
    ];
  };
}
