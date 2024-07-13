inputs:
let
  remoteNixpkgsPatches = [
    {
      meta.description = "Supports multiple efi file checkings for systemd-boot-builder.py";
      url = "https://github.com/NixOS/nixpkgs/pull/326695.patch";
      hash = "sha256-w1boi7mFeqzpyfkZngupAMJPlLrLbJ/UZuqvj9H7xTU=";
    }
  ];
  createSystem =
    { system # String
    , hostname # String
    , modules # [path]
      # [{ username::String;
      #    confPath::path;                home-manager configuration path
      #    osUserConfig::(input: {...});  nixos user configurations
      # }]
    , homes
    , homeModules ? [ ] # [path]
    }:
    let
      originPkgs = inputs.nixpkgs.legacyPackages."${system}";
      nixpkgs = originPkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = map originPkgs.fetchpatch remoteNixpkgsPatches;
      };
      pkgs-staging-next = import inputs.nixpkgs-staging-next { inherit system; };
      lib = originPkgs.lib;
      nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
      usernames = map (h: h.username) homes;
      # Targets for home-manager configurations
      homemanageables = lib.filter (h: h.confPath or null != null) homes;
      # Creates users basic home-manager configurations
      users = lib.foldl
        (acc: elem: {
          "${elem.username}" = { ... }: {
            home = {
              inherit (elem) username;
              homeDirectory = "/home/${elem.username}";
              stateVersion = "23.11";
            };
            imports = [
              elem.confPath
            ];
          };
        } // acc)
        { }
        homemanageables;
    in
    nixosSystem {
      inherit system;
      modules = modules ++ (lib.optionals (users != [ ]) [
        inputs.home-manager.nixosModules.home-manager
        ### home-manager configurations ####
        {
          home-manager = {
            inherit users;
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = homeModules;
            extraSpecialArgs = {
              inherit inputs system;
            };
            backupFileExtension = "backup";
          };
        }
      ]) ++ lib.concatMap

        ### Nixos user settings ###
        (h:
          [
            ({
              users.users."${h.username}" = {
                description = lib.mkDefault "${h.username}";
                isNormalUser = lib.mkDefault true;
                extraGroups = lib.mkDefault [ "networkmanager" "wheel" ];
              };
            })
          ] ++ lib.optional (h.osUserConfig or null != null) h.osUserConfig
        )
        homes;
      specialArgs = {
        inherit inputs hostname usernames pkgs-staging-next;
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
    # System configurations
    maindesk = createSystem {
      system = "x86_64-linux";
      hostname = "maindesk";
      modules = [
        ./maindesk/nixos.nix
        ./../overlay
      ];
      homes = [
        rec {
          username = "turtton";
          confPath = ./maindesk/home-manager.nix;
          osUserConfig = { pkgs, ... }: {
            users.users."${username}" = {
              shell = pkgs.zsh;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
              ];
            };
            imports = [
              (import ./../os/wm/plasma5.nix { inherit username; })
            ];
          };
        }
        rec {
          username = "turtton-hypr";
          confPath = ./maindesk/home-manager-hypr.nix;
          osUserConfig = { pkgs, ... }: {
            users.users."${username}" = {
              shell = pkgs.zsh;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
              ];
            };
            imports = [
              ./../os/wm/hyprland.nix
            ];
            #services.greetd = {
            #  enable = true;
            #  settings = {
            #    default_session = {
            #      command = ''
            #        ${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland
            #      '';
            #      user = username;
            #    };
            #  };
            #};
          };
        }
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
        rec {
          username = "bbridge";
          confPath = ./bridgetop/home-manager.nix;
          osUserConfig = { pkgs, ... }: {
            users.users."${username}" = {
              shell = pkgs.zsh;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
              ];
            };
            imports = [
              (import ./../os/wm/plasma5.nix { inherit username; })
            ];
          };
        }
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
        rec {
          username = "turtton";
          confPath = ./virtbox/home-manager.nix;
          osUserConfig = { pkgs, ... }: {
            users.users."${username}".shell = pkgs.zsh;
            services.greetd = {
              enable = true;
              settings = {
                default_session = {
                  command = ''
                    ${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland
                  '';
                  user = username;
                };
              };
            };
          };
        }
        rec {
          username = "testuser";
          confPath = ./virtbox/home-manager.nix;
          osUserConfig = { pkgs, ... }: {
            users.users."${username}".shell = pkgs.zsh;
          };
        }
      ];
    };
    atticserver = createSystem
      {
        system = "x86_64-linux";
        hostname = "atticserver";
        modules = [
          inputs.attic.nixosModules.atticd
          ./atticserver/nixos.nix
          ./../overlay
        ];
        homes = [
          rec {
            username = "atticserver";
            osUserConfig = { pkgs, ... }: {
              imports = [
                (import ./atticserver/atticd.nix username)
              ];
              users.users."${username}".shell = pkgs.zsh;
            };
          }
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
