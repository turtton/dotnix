# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
{ pkgs, inputs, ... }:
let
  generated = pkgs.callPackage ../_sources/generated.nix { };
  senpi = inputs.senpi.packages.${pkgs.stdenv.hostPlatform.system}.senpi;
in
{
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.rustowl.overlays.default
    inputs.nix-cachyos-kernel.overlays.pinned
    inputs.llm-agents.overlays.default
    (import ./claude-code inputs)
    (import ./codex)
    (import ./opencode inputs)
    (import ./fix-fhs-launcher.nix)
    (import ./fix-dolphin-mime.nix inputs)
    (import ./fix-ime.nix)
    (import ./force-wayland.nix inputs)
    # ORDERING: fix-libreoffice-fonts.nix MUST come before noto-fonts-* overlays.
    # Moving it after any of them breaks the font-pinning logic and causes
    # LibreOffice to rebuild locally instead of being fetched from cache.nixos.org.
    (import ./fix-libreoffice-fonts.nix)
    (import ./noto-fonts-cjk-serif.nix)
    (import ./noto-fonts-cjk-sans.nix)
    (import ./noto-fonts.nix)
    (import ./isaacsim.nix)
    (import ./beutl { inherit (generated) beutl beutl-native-deps; })
    (import ./jetbrains-dolphin.nix generated.jetbrains-dolphin)
    (import ./jetbrains-nautilus.nix generated.jetbrains-nautilus)
    (import ./wallpaper-springcity.nix generated.wallpaper-springcity)
    (import ./blockbench_4.nix inputs)
    (import ./wifiman-desktop.nix)
    (import ./app-replacements.nix inputs)
    #    (import ./webapp.nix)
    (final: prev: {
      inherit senpi;
      # Fix ldap test error(nixpkgs#513245)
      openldap = prev.openldap.overrideAttrs (_: {
        doCheck = !prev.stdenv.hostPlatform.isi686;
      });
    })
  ];
}
