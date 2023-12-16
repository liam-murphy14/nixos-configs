{
  description = "NixOS/NixDarwin system flake configs";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    nixpkgs-darwin = {
      url = "github:nixos/nixpkgs/nixpkgs-23.11-darwin";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager-darwin = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, sops-nix, nix-darwin, nixpkgs-darwin, home-manager-darwin }: 
  let 
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
      pkgs = import nixpkgs { inherit system; };
    });
  in
  {
    nixosConfigurations = {
      old-hp-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./old_hp/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.liam = import ./old_hp/home.nix;
          }
          sops-nix.nixosModules.sops
        ];
      };
      rbpi-nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./rbpi/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.liam = import ./rbpi/home.nix;
          }
          sops-nix.nixosModules.sops
        ];
      };
    };
    darwinConfigurations = {
      mbp-nix-darwin = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./mbp_nix_darwin/configuration.nix
          home-manager-darwin.darwinModules.home-manager
          {
            home-manager-darwin.useGlobalPkgs = true;
            home-manager-darwin.useUserPackages = true;
            home-manager-darwin.users.liammurphy = import ./mbp_nix_darwin/home.nix;
          }
        ];
      };
    };
    formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixpkgs-fmt);
  };
}
