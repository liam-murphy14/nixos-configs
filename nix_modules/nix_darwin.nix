{ inputs, ... }:
let
  inputNixpkgs = inputs.nixpkgs;
in
{
    environment.etc."nixpkgsChannel" = {
      enable = true;
      source = inputNixpkgs;
    };
}

