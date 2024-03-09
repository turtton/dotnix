{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # Hardware settings collection
    xremap.url = "github:xremap/nix-flake"; # KeyMap tool
  };
  outputs = inputs: {
    nixosConfigurations = {
      mainDeskTop = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        specialArgs = {
          inherit inputs;
        };
      };
    };
  };
}