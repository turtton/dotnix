{ inputs, pkgs, ... }: {
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
      accept-flake-config = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        # "https://turtton.cachix.org"
        "https://hyprland.cachix.org"
        "https://ags.cachix.org"
        "https://attic.turtton.net/home"
        "https://attic.taile2777.ts.net"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "turtton.cachix.org-1:+mPRPa0s8CfBEfPCqV/hSSXnaFWfoQJC7bKHLq/k1oE="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
        "home:7Fjx4vYDLZAOseF/QaouAVdlCBiPpIMKj0BPjgieBAE="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    cachix
    attic-client
  ];
}
