{
  description = "Agent skills catalog for dotnix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agent-skills-nix = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotagents = {
      url = "github:turtton/dotagents";
      flake = false;
    };
  };

  outputs =
    {
      self,
      agent-skills-nix,
      dotagents,
      ...
    }:
    {
      homeManagerModules.default = {
        imports = [
          agent-skills-nix.homeManagerModules.default
          (import ./home-manager.nix { inherit dotagents; })
        ];
      };
    };
}
