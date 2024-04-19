inputs:
let
  remoteNixpkgsPatches = [
    {
      meta.description = "Supports multiple efi file checkings for systemd-boot-builder.py";
      url = "https://github.com/turtton/nixpkgs/commit/c0f29cee5621026857062faad73ffbf74b70c0f4.patch";
      hash = "sha256-w1boi7mFeqzpyfkZngupAMJPlLrLbJ/UZuqvj9H7xTU=";
    }
  ];
  createSystem =
    { system # String
    , hostname # String
    , modules # [path]
    , homes # [{ username::String, confPath::path }] Note: this argument can set multiple users but not supported yet because of args limitation
    , homeModules # [path]
    }:
    let
      originPkgs = inputs.nixpkgs.legacyPackages."${system}";
      nixpkgs = originPkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = map originPkgs.fetchpatch remoteNixpkgsPatches;
      };
      pkgs-staging-next = import inputs.nixpkgs-staging-next { inherit system; };
      nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
      usernames = map (h: h.username) homes;
      username = originPkgs.lib.findFirst (x: true) null usernames;
      users = originPkgs.lib.foldl (acc: elem: { "${elem.username}" = elem.confPath; } // acc) { } homes;
    in
    nixosSystem {
      inherit system;
      modules = modules ++ [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = homeModules;
            users = users;
            extraSpecialArgs = {
              inherit inputs usernames username system;
            };
          };
        }
      ];
      specialArgs = {
        inherit inputs hostname username pkgs-staging-next;
      };
    };
  # It is used for darwin or other non nixos systems
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
      modules = [
        ./maindesk/nixos.nix
        ./../overlay
      ];
      homes = [
        { username = "turtton"; confPath = ./maindesk/home-manager.nix; }
      ];
      homeModules = [
        inputs.plasma-manager.homeManagerModules.plasma-manager
      ];
    };
    bridgetop = createSystem {
      system = "x86_64-linux";
      hostname = "bridgetop";
      modules = [
        ./bridgetop/nixos.nix
        ./../overlay
      ];
      homes = [
        { username = "bbridge"; confPath = ./bridgetop/home-manager.nix; }
      ];
      homeModules = [
        inputs.plasma-manager.homeManagerModules.plasma-manager
      ];
    };
    virtbox = createSystem {
      system = "x86_64-linux";
      hostname = "virtbox";
      modules = [
        ./virtbox/nixos.nix
        ./../overlay
      ];
      homes = [
        { username = "turtton"; confPath = ./virtbox/home-manager.nix; }
      ];
      homeModules = [
        inputs.plasma-manager.homeManagerModules.plasma-manager
      ];
    };
  };
  home-manager = {
    /* "turtton@virtbox" = createHomeManagerConfig {
      system = "x86_64-linux";
      username = "turtton";
      modules = [
        ./virtbox/home-manager.nix
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./../overlay
      ]; 
    }; */
  };
}
