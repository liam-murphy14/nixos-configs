{ pkgs, ... }:

let
  vscText = ''
    workspaces=$(find . -maxdepth 2 -type f -name "*.code-workspace")
    if [ -n "$workspaces" ]; then
      output=$workspaces 
    else
      output="."
    fi

    code-insiders $output
  '';
  vscScript = pkgs.writeShellScriptBin "vsc" vscText;
in

{
  home.packages = [ vscScript ];
}
