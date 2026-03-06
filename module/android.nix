{
  pkgs,
  lib,
  config,
  isHomeManager,
  hostPlatform,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption optionals;

  cfg = config.packs.android;

  # Wrapper script for Android emulator to fix library loading on NixOS.
  # The emulator overrides LD_LIBRARY_PATH when launching qemu, dropping
  # nix-ld's library path. This wrapper injects NIX_LD_LIBRARY_PATH into
  # LD_LIBRARY_PATH before the emulator runs, and sets QT_QPA_PLATFORM=xcb
  # to avoid Qt Wayland issues.
  emulatorWrapper = pkgs.writeShellScript "android-emulator-wrapper" ''
    export QT_QPA_PLATFORM=xcb
    export LD_LIBRARY_PATH="''${NIX_LD_LIBRARY_PATH}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec "$(dirname "$0")/emulator.orig" "$@"
  '';
in
{
  options.packs.android.enable = mkEnableOption "Android development environment";

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        home.packages =
          with pkgs;
          optionals hostPlatform.isLinux [
            android-studio
          ];

        home.activation.wrapAndroidEmulator = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          EMULATOR_BIN="$HOME/Android/Sdk/emulator/emulator"
          EMULATOR_ORIG="$HOME/Android/Sdk/emulator/emulator.orig"

          if [ -f "$EMULATOR_BIN" ]; then
            # Wrap only if emulator is an ELF binary (not already wrapped)
            if ${pkgs.file}/bin/file "$EMULATOR_BIN" | grep -q "ELF"; then
              mv "$EMULATOR_BIN" "$EMULATOR_ORIG"
              cp ${emulatorWrapper} "$EMULATOR_BIN"
              chmod +x "$EMULATOR_BIN"
            fi
          fi
        '';
      }
    else
      {
        environment.systemPackages =
          with pkgs;
          optionals hostPlatform.isLinux [
            android-tools
          ];
      }
  );
}
