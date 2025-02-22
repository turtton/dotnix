{
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://ags.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-staging-next.url = "github:NixOS/nixpkgs/staging-next";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    ags.url = "github:aylur/ags";
    hyprpolkitagent.url = "github:hyprwm/hyprpolkitagent";
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
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ nixpkgs, flake-utils, hyprland, hyprpanel, hyprpolkitagent, rust-overlay, ... }: {
    nixosConfigurations = (import ./hosts inputs).nixos;
    homeConfigurations = (import ./hosts inputs).home-manager;
    darwinConfigurations = (import ./hosts inputs).darwin;
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; overlays = [ (import rust-overlay) ]; };
      overlays = pkgs.lib.attrsets.mergeAttrsList (map (overlay: overlay pkgs pkgs) (import ./overlay/d-linux.nix { inherit pkgs inputs; }).nixpkgs.overlays);
    in
    with pkgs; {
      formatter = nixpkgs-fmt;
      packages = {
        ghr = overlays.ghr;
        rustowl = overlays.rustowl;
        jetbrains-dolphin-qt5 = overlays.jetbrains-dolphin-qt5;
        jetbrains-dolphin-qt6 = overlays.jetbrains-dolphin-qt6;
        jetbrains-nautilus = overlays.jetbrains-nautilus;
        noto-fonts-cjk-sans = overlays.noto-fonts-cjk-sans;
        noto-fonts-cjk-serif = overlays.noto-fonts-cjk-serif;
        noto-fonts = overlays.noto-fonts;
        wallpaper-springcity = overlays.wallpaper-springcity;
        hyprland = hyprland.packages.${system}.default;
        hyprpanel = hyprpanel.packages.${system}.default;
        hyprpolkitagent = hyprpolkitagent.packages.${system}.default;
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
        zoom-us = overlays.zoom-us;
        zen-browser = inputs.zen-browser.packages.${system}.default;
        # pake-cli = overlays.pake-cli;
        # fastmail = overlays.fastmail;
      };
      devShells.default = mkShell {
        packages = [
          nvfetcher
          home-manager
          (writeScriptBin "switch-home" ''
            home-manager switch --flake ".#$@" --show-trace
          '')
          (writeScriptBin "switch-nixos" ''
            ulimit -n 4096 && sudo nixos-rebuild switch --flake ".#$@" --show-trace
          '')
          (writeScriptBin "switch-darwin" ''
            nix run nix-darwin -- switch --flake ".#$@" --show-trace
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
