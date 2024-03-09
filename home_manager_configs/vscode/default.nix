{ ... }:

{
  imports = [ ./vsc.nix ];
  programs.vscode = {
    enable = true;
  };
}
