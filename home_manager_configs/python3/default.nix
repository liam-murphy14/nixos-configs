{ pkgs, ... }:

let
  my-python-packages =
    ps: with ps; [
      ipython
      matplotlib
      pandas
      numpy
      black
    ];
in
{

  home.file.".ipython/profile_default/ipython_config.py".source = ./ipython_config.py;

  home.packages = with pkgs; [
    # PYTHON
    (python3.withPackages my-python-packages)
  ];
}
