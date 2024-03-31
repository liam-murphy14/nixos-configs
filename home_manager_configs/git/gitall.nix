{ pkgs, ... }:

let
  gitallText = ''
    git add .
    if [ -n "$1" ]
    then
        git commit -m "$1"
    else
        git commit -m update
    fi
    git push origin HEAD
  '';
  gitallScript = pkgs.writeShellScriptBin "gitall" gitallText;
in

{
  home.packages = [ gitallScript ];
}
