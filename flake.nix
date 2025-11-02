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

  outputs = { self, nixpkgs, home-manager, sops-nix, nix-darwin, python-serverless-housefire }@inputs:
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
            ./nix_modules/housefire.nix
          ];
        };
      };
      darwinConfigurations = {
        mbp-nix-darwin = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./mbp_nix_darwin/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.liammurphy = import ./mbp_nix_darwin/home.nix;
            }
          ];
        };
      };
      homeConfigurations = {
        # for work machines where I dont want to configure the entire OS
        murplia-mac = home-manager.lib.homeManagerConfiguration {
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim ];
              zon_home.homeDirectoryPath = "/Users/murplia";
              zon_home.extraPreInit = ''
                eval "$(/opt/homebrew/bin/brew shellenv)"
              '';
              zon_home.extraInitExtra = ''
                [[ -f "/Users/murplia/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "/Users/murplia/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
              '';
            }
          ];
        };
        murplia-cloud = home-manager.lib.homeManagerConfiguration {
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim ];
              zon_home.homeDirectoryPath = "/home/murplia";
              zon_home.extraInitExtra = ''
                [[ -f "/home/murplia/.local/share/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "/home/murplia/.local/share/amazon-q/shell/zshrc.post.zsh"
                export PATH=$PATH:/home/murplia/.local/share/mise/installs/node/22.16.0/bin
              '';
            }
          ];
        };
        murplia-86-cloud = home-manager.lib.homeManagerConfiguration {
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim ];
              zon_home.homeDirectoryPath = "/home/murplia";
              zon_home.extraInitExtra = ''
                [[ -f "/home/murplia/.local/share/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "/home/murplia/.local/share/amazon-q/shell/zshrc.post.zsh"
              '';
            }
          ];
        };
        murplia-86-cloud-mini = home-manager.lib.homeManagerConfiguration {
          modules = [
            ./zon_home/home.nix
            {
              imports = [ ./home_manager_configs/neovim/minimum_zon.nix ];
              zon_home.homeDirectoryPath = "/home/murplia";
              zon_home.extraInitExtra = ''
                [[ -f "/home/murplia/.local/share/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "/home/murplia/.local/share/amazon-q/shell/zshrc.post.zsh"
              '';
            }
          ];
        };
      };
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixpkgs-fmt);
    };
}
