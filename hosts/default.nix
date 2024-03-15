inputs: 
let
  createSystem = {
    system,
    hostname,
    username,
    modules
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system modules;
    specialArgs = {
      inherit inputs hostname username;
    };
  };
  createHomeManagerConfig = {
    system,
    username,
    overlays,
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
      overlays = [(import inputs.rust-overlay)];
      modules = [
        ./maindesk/home-manager.nix
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./../overlay
      ];
    };
    "turtton@virtbox" = createHomeManagerConfig {
      system = "x86_64-linux";
      username = "turtton";
      overlays = [(import inputs.rust-overlay)];
      modules = [
        ./virtbox/home-manager.nix
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./../overlay
      ];
    };
  };
}