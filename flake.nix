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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    python-serverless-housefire = {
      url = "github:liam-murphy14/python_serverless_housefire";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      nix-darwin,
      python-serverless-housefire,
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );

    in
    {
      nixosConfigurations = {
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
            ./nix_modules/housefire.nix
          ];
        };
      };
      darwinConfigurations = {
        mba-nix-darwin = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./mba_nix_darwin/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.liammurphy = import ./mba_nix_darwin/home.nix;
            }
          ];
        };
      };
      homeConfigurations = {
        # for work machines where I dont want to configure the entire OS
        murplia-mac = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim ];
              zon_home.homeDirectoryPath = "/Users/murplia";
              zon_home.extraPreInit = ''
                eval "$(/opt/homebrew/bin/brew shellenv)"
              '';
            }
          ];
        };
        murplia-cloud = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-linux";
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim ];
              zon_home.homeDirectoryPath = "/home/murplia";
            }
          ];
        };
        murplia-86-cloud = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim ];
              zon_home.homeDirectoryPath = "/home/murplia";
            }
          ];
        };
      };
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-tree);
    };
}
