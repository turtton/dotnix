{
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-staging-next.url = "github:NixOS/nixpkgs/staging-next";
    nixos-hardware.url =
      "github:NixOS/nixos-hardware/master"; # Hardware settings collection
    xremap.url = "github:xremap/nix-flake"; # KeyMap tool
    # Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      # Plasma 5 support branch
      url = "github:pjones/plasma-manager/plasma-5";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    utils.url = "github:numtide/flake-utils";
    turtton-neovim.url = "github:turtton/myvim.nix";
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ nixpkgs, flake-utils, hyprpanel, ... }: {
    nixosConfigurations = (import ./hosts inputs).nixos;
    homeConfigurations = (import ./hosts inputs).home-manager;
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      overlays = pkgs.lib.attrsets.mergeAttrsList (map (overlay: overlay pkgs pkgs) (import ./overlay { inherit pkgs; }).nixpkgs.overlays);
    in
    with pkgs; {
      formatter = nixpkgs-fmt;
      packages = {
        ghr = overlays.ghr;
        jetbrains-dolphin-qt5 = overlays.jetbrains-dolphin-qt5;
        jetbrains-dolphin-qt6 = overlays.jetbrains-dolphin-qt6;
        jetbrains-nautilus = overlays.jetbrains-nautilus;
        wallpaper-springcity = overlays.wallpaper-springcity;
        hyprpanel = hyprpanel.packages.${system}.default;
        hyprpanel-tokyonight = overlays.hyprpanel-tokyonight;
        # Force Wayland IME system
        vivaldi = overlays.vivaldi;
        chromium = overlays.chromium;
        spotify = overlays.spotify;
        obsidian = overlays.obsidian;
        discord = overlays.discord;
        discord-ptb = overlays.discord-ptb;
        slack = overlays.slack;
        teams-for-linux = overlays.teams-for-linux;
        vscode = overlays.vscode;
      };
      devShells.default = mkShell {
        packages = [
          nvfetcher
          home-manager
          (writeScriptBin "switch-home" ''
            home-manager switch --flake ".#$@" --show-trace
          '')
          (writeScriptBin "switch-nixos" ''
            sudo nixos-rebuild switch --flake ".#$@" --show-trace
          '')
          (writeScriptBin "gen-template" ''
            nix run github:nix-community/nixos-generators -- -f proxmox-lxc --flake ".#$@" --show-trace
          '')

          # For xmonad
          # (haskellPackages.ghcWithPackages (hpkgs: [  
          #   hpkgs.xmonad
          #   hpkgs.xmonad-contrib
          # ]))
        ];
      };
    });
}
