# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Nix/NixOS configuration repository that manages system configurations for multiple machines using Nix flakes. It supports both NixOS (Linux) and Darwin (macOS) systems with a focus on reproducible desktop environments.

## Common Development Commands

### System Management

- `nix develop` - Enter development shell with helper commands
- `switch-nixos {hostname}` - Rebuild and switch NixOS configuration for a host
- `switch-darwin {hostname}` - Rebuild and switch Darwin configuration
- `switch-home {hostname}` - Switch home-manager configuration (legacy, integrated into system configs now)
- `gen-template {hostname}` - Generate NixOS templates (e.g., for Proxmox LXC)

### Development Tools

- `nix fmt` - Format all code using treefmt (nixfmt, taplo, biome, stylish-haskell, yamlfmt, mdformat, shfmt)
- `nvfetcher` - Update external package sources in \_sources/

### Available Hosts

- **NixOS**: maindesk, bridgetop, virtbox, atticserver
- **Darwin**: dreamac

## Architecture

### Module Organization

- **`hosts/`** - Per-machine configurations with hardware settings and system/user configs
- **`home-manager/`** - User environment configurations:
  - `cli/` - Terminal tools and development environments
  - `gui/` - GUI applications
  - `wm/` - Window manager configs (Hyprland, XMonad, Aerospace)
- **`os/`** - System-level NixOS modules:
  - `core/` - Essential services (network, SSH, locale)
  - `desktop/` - Desktop services (fonts, sound, 1Password)
  - `wm/` - Window manager system services
- **`overlay/`** - Custom package definitions and modifications
- **`darwin/`** - macOS-specific system configurations

### Key Patterns

- Host configurations combine hardware settings, system modules, and user configs
- Overlays modify packages globally (e.g., forcing Wayland, IME fixes)
- State version is pinned to 23.11 for compatibility
- Uses Cachix for Hyprland and AGS binary caches

### External Dependencies

- nvfetcher tracks external sources defined in `nvfetcher.toml`
- Generated sources are stored in `_sources/`
- Custom packages include: beutl, claude-code, rustowl, various Wayland/IME fixes

## Important Notes

- When modifying host configurations, ensure hardware-configuration.nix matches the target system
- The repository uses experimental Nix features: nix-command and flakes
- Plasma configurations use generated files from plasma2nix
- Window manager configurations are host-specific (see home-manager-\*.nix files)
