# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Nix flake managing NixOS (Linux) and nix-darwin (macOS) systems. The current primary desktop is **niri** with noctalia-shell (see README). Hyprland and XMonad configs are still in tree but outdated.

## Common Development Commands

`nix develop` provides:

- `switch-nixos {hostname}` - Rebuild and switch a NixOS host
- `remote-switch-nixos {hostname} [target-host]` - Same, over SSH (target defaults to hostname)
- `switch-darwin {hostname}` - Rebuild and switch a Darwin host
- `switch-home {hostname}` - Standalone home-manager (legacy; HM is integrated into the system configs)
- `gen-template {hostname}` - Generate NixOS templates (e.g. for Proxmox LXC)

Other:

- `nix fmt` - treefmt (nixfmt, taplo, biome, stylish-haskell, yamlfmt, mdformat, shfmt)
- `nvfetcher` - Regenerate `_sources/` from `nvfetcher.toml`. Use `nvfetcher --filter <pkg>` to avoid bumping unrelated packages.

### Available Hosts

- **NixOS**: maindesk, bridgetop, virtbox, atticserver, wslac
- **Darwin**: dreamac

## Architecture

### `module/` - the shared module layer

`module/` is injected into home-manager `sharedModules` for *every* configuration — NixOS, Darwin, and standalone HM (`hosts/default.nix:62,77,191`). Most subdirectories declare a `packs.<name>.enable` option defaulting to off, so hosts opt in:

```nix
packs.niri.enable = true;
packs.noctalia.enable = true;
```

**niri lives in `module/niri/`, not `home-manager/wm/`.** `home-manager/wm/` holds the older per-user WM configs (hyprland, xmonad, aerospace) plus `omniwm/` for macOS.

### Layout

- **`hosts/`** - Per-machine entry points. `hosts/default.nix` holds the `createNixosConfig` / `createDarwinConfig` builders and every host definition. A host's WM is selected by a `confPath` pointing at `hosts/<host>/home-manager-*.nix`.
- **`os/`** - NixOS system modules: `core/{common,desktop,server,secureboot}`, `desktop/`, `wm/`
- **`darwin/`** - nix-darwin system modules
- **`home-manager/{cli,gui,wm}/`** - User environment
- **`overlay/`** - Package definitions and global fixes
- **`nixosModules/`** + **`packages/`** - `preloader-signed` (PreLoader/HashTool for UEFI Secure Boot with systemd-boot), exported as flake outputs
- **`skills/`** - Nested flake with its own `flake.lock` for the agent skills catalog

### Overlays

`overlay/d-linux.nix` and `overlay/d-darwin.nix` are the platform entry points — a new package must be registered in the right one. Both bind `generated = pkgs.callPackage ../_sources/generated.nix { }`, and nvfetcher-backed overlay files take their entry as the first argument:

```nix
(import ./omniwm.nix generated.omniwm)
```

Ordering within `d-linux.nix` is load-bearing in one place; see the `fix-libreoffice-fonts` comment before reordering.

### State versions

NixOS pins `stateVersion = "23.11"` (`hosts/default.nix:4`). Darwin uses `system.stateVersion = 5`.

## macOS (dreamac) specifics

- `mac-app-util` is wired into both `darwinModules` and HM `sharedModules`, giving GUI apps stable `/Applications` trampolines so TCC (Accessibility) grants survive store path changes.
- Homebrew taps/casks are declared in `darwin/homebrew.nix` and managed by nix-darwin with `onActivation.cleanup = "zap"`, so deleting an entry uninstalls it. Note `autoUpdate` does not upgrade already-installed casks.
- Digital Guardian (`dgagent`/`dgesc`) intercepts reads on freshly written files and returns transient `EPERM`. This breaks JetBrains builds — both while copying the DMG contents and while nix hashes `$out` afterwards, which leaves the output unregistered and causes a rebuild loop. `overlay/d-darwin.nix` works around it by waiting for readability in `preInstall` and `postInstall`. Expect this to resurface with any large bundled asset.

## Comments

Match the comment density of the surrounding code. Before finishing a new file, open the nearest equivalent existing file and compare — e.g. `module/niri/settings.nix` (~3%), `home-manager/wm/aerospace/default.nix` (0%). Target 10% or below.

Only two things earn a comment:

1. An external constraint the code cannot express, where a reader would otherwise "fix" it and break something. Examples: `bsdtar` is required in `overlay/omniwm.nix` or the notarized signature breaks; the JetBrains darwin builder sets `dontFixup = true` so `postFixup` never runs.
1. Load-bearing ordering or invariants, such as the `fix-libreoffice-fonts` ORDERING note.

Do not write: what the code already states; translation tables against the tool being replaced; justifications for the approach *not* taken; investigation history; or version-specific details that will rot. Those belong in the commit message or the conversation.
