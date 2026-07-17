{
  pkgs,
  lib,
  config,
  ...
}:

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
  options.my_python = {
    extraPackages = lib.mkOption {
      default = x: [ ];
      type = lib.types.raw;
    };
  };

  config = {
    home.file.".ipython/profile_default/ipython_config.py".source = ./ipython_config.py;

    home.packages = with pkgs; [
      # PYTHON
      (python3.withPackages (ps: (my-python-packages ps) ++ (config.my_python.extraPackages ps)))
    ];
  };
}
