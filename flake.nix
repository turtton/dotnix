{
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://ags.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-staging-next.url = "github:NixOS/nixpkgs/staging-next";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # Hardware settings collection
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
    ags.url = "github:aylur/ags";
    hyprpolkitagent = {
      url = "github:hyprwm/hyprpolkitagent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    utils.url = "github:numtide/flake-utils";
    turtton-neovim = {
      url = "github:turtton/myvim.nix";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      #url = "github:turtton/claude-desktop-linux-flake/turtton";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    rustowl = {
      url = "github:nix-community/rustowl-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    winapps = {
      url = "github:winapps-org/winapps";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    direnv-instant = {
      url = "github:Mic92/direnv-instant";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };
  outputs =
    inputs@{
      nixpkgs,
      flake-utils,
      hyprland,
      hyprpolkitagent,
      rust-overlay,
      treefmt-nix,
      claude-desktop,
      rustowl,
      noctalia,
      niri-flake,
      ...
    }:
    {
      nixosConfigurations = (import ./hosts inputs).nixos;
      homeConfigurations = (import ./hosts inputs).home-manager;
      darwinConfigurations = (import ./hosts inputs).darwin;
      nixosModules = {
        preloader-signed = import ./nixosModules/preloader-signed.nix;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ (import rust-overlay) ];
        };
        overlayFile = if pkgs.stdenv.isLinux then ./overlay/d-linux.nix else ./overlay/d-darwin.nix;
        overlays = pkgs.lib.attrsets.mergeAttrsList (
          map (overlay: overlay pkgs pkgs) (import overlayFile { inherit pkgs inputs; }).nixpkgs.overlays
        );
      in
      with pkgs;
      {
        formatter = treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            taplo.enable = true;
            biome.enable = true;
            stylish-haskell.enable = true;
            yamlfmt.enable = true;
            mdformat.enable = true;
            shfmt.enable = true;
          };
          settings = {
            global.excludes = [
              ".direnv/*"
              "_sources/*"
              "overlay/beutl/deps.json"
              "home-manager/wm/hyprland/waybar/*.css"
            ];
          };
        };
        packages = {
          rustowl = rustowl.packages.${system}.default;
          claude-code = overlays.claude-code;
        }
        // lib.optionalAttrs stdenv.hostPlatform.isLinux (
          let
            preloader-signed = import ./packages/preloader-signed.nix { inherit pkgs; };
          in
          {
            inherit (preloader-signed) preLoader hashTool;
            beutl = overlays.beutl;
            jetbrains-dolphin-qt5 = overlays.jetbrains-dolphin-qt5;
            jetbrains-dolphin-qt6 = overlays.jetbrains-dolphin-qt6;
            jetbrains-nautilus = overlays.jetbrains-nautilus;
            noto-fonts-cjk-sans = overlays.noto-fonts-cjk-sans;
            noto-fonts-cjk-serif = overlays.noto-fonts-cjk-serif;
            noto-fonts = overlays.noto-fonts;
            wallpaper-springcity = overlays.wallpaper-springcity;
            hyprland = hyprland.packages.${system}.default;
            hyprpolkitagent = hyprpolkitagent.packages.${system}.default;
            zen-browser = inputs.zen-browser.packages.${system}.default;
            isaacsim-webrtc-streaming-client = overlays.isaacsim-webrtc-streaming-client;
            claude-desktop = overlays.claude-desktop;
            dolphin = overlays.kdePackages.dolphin;
            # wifiman-desktop = overlays.wifiman-desktop;
            # pake-cli = overlays.pake-cli;
            # fastmail = overlays.fastmail;
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
            noctalia-shell = noctalia.packages.${system}.default;
            xwayland-satellite = niri-flake.packages.${system}.xwayland-satellite-unstable;
          }
        );
        devShells.default = mkShell {
          packages = [
            nvfetcher
            home-manager
            pinact
            zizmor
            nh
            gh
            (writeScriptBin "switch-home" ''
              nh home switch . -C"$@"
            '')
            (writeScriptBin "switch-nixos" ''
              ulimit -n 4096 && nh os switch . -H "$@"
            '')
            (writeScriptBin "switch-darwin" ''
              nh darwin switch . -H "$@"
            '')
            (writeScriptBin "gen-template" ''
              nix run github:nix-community/nixos-generators -- -f proxmox-lxc --flake ".#$@" --show-trace
            '')
            (writeScriptBin "update-flake" ''
              NIX_CONFIG="access-tokens = github.com=$(gh auth token)" nix flake update "$@"
            '')

            # For xmonad
            # (haskellPackages.ghcWithPackages (hpkgs: [
            #   hpkgs.xmonad
            #   hpkgs.xmonad-contrib
            # ]))
          ];
        };
      }
    );
}
