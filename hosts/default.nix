inputs:
let
  remoteNixpkgsPatches = [
    {
      meta.description = "Supports multiple efi file checkings for systemd-boot-builder.py";
      url = "https://github.com/turtton/nixpkgs/commit/c0f29cee5621026857062faad73ffbf74b70c0f4.patch";
      hash = "sha256-w1boi7mFeqzpyfkZngupAMJPlLrLbJ/UZuqvj9H7xTU=";
    }
    {
      meta.description = "Revert xz updates";
      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/300028.patch";
      hash = "sha256-m0UcwF7krpJJbQE4GDerWjKjGkayqqUTBaF1WGw2xPk=";
    }
    {
      meta.description = "Change xz repostiory";
      url = "https://github.com/NixOS/nixpkgs/commit/6aa50d08087b8a5265ca3a41174341245ed69fe0.patch";
      hash = "sha256-tGYGFzM9djDyRp2M7kd8LtifxCfoHDfFE6A/DfLcc/w=";
    }
  ];
  createSystem =
    { system
    , hostname
    , username
    , modules
    }:
    let
      originPkgs = inputs.nixpkgs.legacyPackages."${system}";
      nixpkgs = originPkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = map originPkgs.fetchpatch remoteNixpkgsPatches;
      };
      nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
    in
    nixosSystem {
      inherit system modules;
      specialArgs = {
        inherit inputs hostname username;
      };
    };
  createHomeManagerConfig =
    { system
    , username
    , overlays ? [ ]
    , modules
    }: inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config = {
          allowUnfree = true;
        };
      };
      extraSpecialArgs = {
        inherit inputs username system;
      };
      modules = modules ++ [
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
            stateVersion = "23.11";
          };
          programs.home-manager.enable = true;
        }
      ];
    };
in
{
  nixos = {
    maindesk = createSystem {
      system = "x86_64-linux";
      hostname = "maindesk";
      username = "turtton";
      modules = [
        ./maindesk/nixos.nix
        ./../overlay
      ];
    };
    virtbox = createSystem {
      system = "x86_64-linux";
      hostname = "virtbox";
      username = "turtton";
      modules = [
        ./virtbox/nixos.nix
        ./../overlay
      ];
    };
  };
  home-manager = {
    "turtton@maindesk" = createHomeManagerConfig {
      system = "x86_64-linux";
      username = "turtton";
      modules = [
        ./maindesk/home-manager.nix
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./../overlay
      ];
    };
    "turtton@virtbox" = createHomeManagerConfig {
      system = "x86_64-linux";
      username = "turtton";
      modules = [
        ./virtbox/home-manager.nix
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./../overlay
      ];
    };
  };
}
