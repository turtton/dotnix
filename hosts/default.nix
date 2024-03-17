inputs: 
let
  remoteNixpkgsPatches = [
    {
      meta.description = "Supports multiple efi file checkings for systemd-boot-builder.py";
      url = "https://github.com/turtton/nixpkgs/commit/c0f29cee5621026857062faad73ffbf74b70c0f4.patch";
      hash = "sha256-w1boi7mFeqzpyfkZngupAMJPlLrLbJ/UZuqvj9H7xTU=";
    }
  ];
  createSystem = {
    system,
    hostname,
    username,
    modules
  }: let 
    originPkgs = inputs.nixpkgs.legacyPackages."${system}";
    nixpkgs = originPkgs.applyPatches {
      name = "nixpkgs-patched";
      src = inputs.nixpkgs;
      patches = map originPkgs.fetchpatch remoteNixpkgsPatches;
    };
    nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
  in nixosSystem {
    inherit system modules;
    specialArgs = {
      inherit inputs hostname username;
    };
  };
  createHomeManagerConfig = {
    system,
    username,
    overlays ? [],
    modules
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
in {
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