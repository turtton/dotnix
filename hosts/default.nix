inputs:
let
  remoteNixpkgsPatches = [
    # {
    #   meta.description = "Fix bs-manager build";
    #   url = "https://github.com/NixOS/nixpkgs/pull/476063.patch";
    #   hash = "sha256-wrkCKT2v+KHSMXvtGcec6hwrXe5idxlipyceDyrPXeY=";
    # }
  ];
  stateVersion = "23.11";
  createSystem =
    {
      system, # String
      hostname, # String
      modules, # [path]
      # [{ username::String;
      #    confPath::path;                home-manager configuration path
      #    osUserConfig::(input: {...});  nixos user configurations
      # }]
      homes,
      homeModules ? [ ], # [path]
      sharedOptions ? { }, # Additional options to be passed to home-manager and nixos
    }:
    let
      originPkgs = inputs.nixpkgs.legacyPackages.${system};
      nixpkgs = originPkgs.applyPatches {
        name = "nixpkgs-patched";
        src = inputs.nixpkgs;
        patches = map originPkgs.fetchpatch remoteNixpkgsPatches;
      };
      pkgs-staging-next = import inputs.nixpkgs-staging-next {
        inherit system;
        config.allowUnfree = true;
      };
      lib = originPkgs.lib;
      hostPlatform = originPkgs.stdenv.hostPlatform;
      nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
      usernames = map (h: h.username) homes;
      # Targets for home-manager configurations
      homemanageables = lib.filter (h: h.confPath or null != null) homes;
      # Creates users basic home-manager configurations
      users = lib.foldl (
        acc: elem:
        {
          "${elem.username}" =
            { ... }:
            {
              home = {
                inherit (elem) username;
                inherit stateVersion;
                homeDirectory = "/home/${elem.username}";
              };
              imports = [
                elem.confPath
              ];
            };
        }
        // acc
      ) { } homemanageables;
    in
    nixosSystem {
      inherit system;
      modules =
        modules
        ++ [
          ./../overlay/d-linux.nix
          ./../module
          sharedOptions
        ]
        ++ (lib.optionals (users != [ ]) [
          inputs.home-manager.nixosModules.home-manager
          ### home-manager configurations ####
          {
            home-manager = {
              inherit users;
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = homeModules ++ [
                inputs.claude-code-overlay.homeManagerModules.default
                ./../module
                sharedOptions
              ];
              extraSpecialArgs = {
                inherit
                  inputs
                  system
                  hostPlatform
                  pkgs-staging-next
                  ;
                isHomeManager = true;
              };
              backupFileExtension = "backup";
            };
          }
          {
            system.stateVersion = stateVersion;
          }
        ])
        ++
          lib.concatMap

            ### Nixos user settings ###
            (
              h:
              [
                ({
                  users.users."${h.username}" = {
                    description = lib.mkDefault "${h.username}";
                    isNormalUser = lib.mkDefault true;
                    extraGroups = lib.mkDefault [
                      "networkmanager"
                      "wheel"
                      "dialout"
                      "adbusers"
                      "kvm"
                    ];
                  };
                })
              ]
              ++ lib.optional (h.osUserConfig or null != null) h.osUserConfig
            )
            homes;
      specialArgs = {
        inherit
          inputs
          hostname
          usernames
          system
          pkgs-staging-next
          hostPlatform
          ;
        isHomeManager = false;
      };
    };
  createDarwinConfig =
    {
      system,
      hostname,
      username,
      modules,
      homeModule,
    }:
    let
      originPkgs = inputs.nixpkgs.legacyPackages.${system};
      hostPlatform = originPkgs.stdenv.hostPlatform;
      # nixpkgs = originPkgs.applyPatches {
      #   name = "nixpkgs-patched";
      #   src = inputs.nixpkgs;
      #   patches = map originPkgs.fetchpatch remoteNixpkgsPatches;
      # };
      homeDirectory = "/Users/${username}";
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit
          inputs
          hostname
          username
          system
          hostPlatform
          ;
      };
      modules = modules ++ [
        ./../overlay/d-darwin.nix
        inputs.home-manager.darwinModules.home-manager
        {
          networking.hostName = hostname;
          users.users."${username}".home = homeDirectory;
          nixpkgs.hostPlatform = system;
          system.stateVersion = 5;
          system.primaryUser = username;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users."${username}" = homeModule // {
              home = {
                inherit username stateVersion homeDirectory;
                enableNixpkgsReleaseCheck = true;
              };
            };
            extraSpecialArgs = {
              inherit
                inputs
                system
                username
                hostPlatform
                ;
            };
          };
        }
      ];
    };
  # It is used for non nixos systems
  createHomeManagerConfig =
    {
      system,
      username,
      overlays ? [ ],
      modules,
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config = {
          allowUnfree = true;
        };
      };
      hostPlatform = pkgs.stdenv.hostPlatform;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit
          inputs
          username
          system
          hostPlatform
          ;
      };
      modules = modules ++ [
        {
          home = {
            inherit username stateVersion;
            homeDirectory = "/home/${username}";
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
      ];
      homes = [
        rec {
          username = "turtton";
          confPath = ./maindesk/home-manager-niri.nix;
          osUserConfig =
            { pkgs, ... }:
            {
              users.users."${username}" = {
                shell = pkgs.zsh;
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
                ];
              };
              # imports = [
              #   (import ./../os/wm/plasma5.nix { inherit username; })
              # ];
              services.greetd = {
                enable = true;
                settings = {
                  initial_session = {
                    command = "niri-session";
                    user = username;
                  };
                  default_session = {
                    command = ''
                      ${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session
                    '';
                    user = username;
                  };
                };
              };
            };
        }
      ];
      homeModules = [
        inputs.plasma-manager.homeManagerModules.plasma-manager
      ];
      sharedOptions = {
        packs.niri.enable = true;
        packs.bemoji.enable = true;
        packs.android.enable = true;
        packs.remote-desktop = {
          enable = true;
          server = true;
        };
        packs.winapps.enable = true;
        packs.vial.enable = true;
      };
    };
    bridgetop = createSystem {
      system = "x86_64-linux";
      hostname = "bridgetop";
      modules = [
        ./bridgetop/nixos.nix
      ];
      homes = [
        rec {
          username = "bbridge";
          confPath = ./bridgetop/home-manager-niri.nix;
          osUserConfig =
            { pkgs, ... }:
            {
              users.users."${username}" = {
                shell = pkgs.zsh;
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
                ];
              };
              # imports = [
              #   (import ./../os/wm/plasma5.nix { inherit username; })
              # ];
              services.greetd = {
                enable = true;
                settings = {
                  initial_session = {
                    command = "niri-session";
                    user = username;
                  };
                  default_session = {
                    command = ''
                      ${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session
                    '';
                    user = username;
                  };
                };
              };
            };
        }
      ];
      homeModules = [
        inputs.plasma-manager.homeManagerModules.plasma-manager
      ];
      sharedOptions = {
        packs.niri.enable = true;
        packs.bemoji.enable = true;
        packs.remote-desktop.enable = true;
        packs.vial.enable = true;
      };
    };
    virtbox = createSystem {
      system = "x86_64-linux";
      hostname = "virtbox";
      modules = [
        ./virtbox/nixos.nix
      ];
      homes = [
        rec {
          username = "turtton";
          confPath = ./virtbox/home-manager-hypr.nix;
          osUserConfig =
            { pkgs, ... }:
            {
              users.users."${username}".shell = pkgs.zsh;
              services.greetd = {
                enable = true;
                settings = {
                  initial_session = {
                    command = "Hyprland";
                    user = username;
                  };
                  default_session = {
                    command = ''
                      ${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland
                    '';
                    user = username;
                  };
                };
              };
            };
        }
        # rec {
        #   username = "testuser";
        #   confPath = ./virtbox/home-manager-hypr.nix;
        #   osUserConfig = { pkgs, ... }: {
        #     users.users."${username}".shell = pkgs.zsh;
        #   };
        # }
      ];
      sharedOptions = {
        packs.bemoji.enable = true;
      };
    };
    atticserver = createSystem {
      system = "x86_64-linux";
      hostname = "atticserver";
      modules = [
        ./atticserver/nixos.nix
      ];
      homes = [
        rec {
          username = "atticserver";
          confPath = ./atticserver/home-manager.nix;
          osUserConfig =
            { pkgs, ... }:
            {
              users.users."${username}" = {
                shell = pkgs.zsh;
                hashedPassword = "$y$j9T$YBM6ZWl/jcXc0PAV6QMWd.$ZK0sLnObalAYMcFlAXRViFDdkOzkszowP3CWtEo.ky6";
                group = "users";
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/8nfHCulkm71YTzMXgrvTF+G9RQ9LUvy6pKat/FXot"
                ];
              };
            };
        }
      ];
    };
  };
  darwin = {
    "dreamac" = createDarwinConfig {
      system = "aarch64-darwin";
      hostname = "dreamac";
      username = "s_ohashi";
      modules = [
        ./dreamac/darwin.nix
      ];
      homeModule = import ./dreamac/home-manager.nix;
    };
  };
  home-manager = {
    /*
      "turtton@virtbox" = createHomeManagerConfig {
      system = "x86_64-linux";
      username = "turtton";
      modules = [
        ./virtbox/home-manager.nix
        inputs.plasma-manager.homeManagerModules.plasma-manager
        ./../overlay
      ];
        };
    */
  };
}
