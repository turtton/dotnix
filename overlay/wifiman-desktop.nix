self: prev: with self; {
  wifiman-desktop = stdenv.mkDerivation (finalAttrs: {
    pname = "wifiman-desktop";
    version = "1.2.8";

    src = fetchurl {
      url = "https://desktop.wifiman.com/wifiman-desktop-${finalAttrs.version}-amd64.deb";
      hash = "sha256-R+MbwxfnBV9VcYWeM1NM08LX1Mz9+fy4r6uZILydlks=";
    };

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      webkitgtk_4_1
      gtk3
      glib
      libsoup_3
      libayatana-appindicator
    ];

    installPhase =
      let
        runtimePath = lib.makeBinPath [
          iw
          net-tools
          wirelesstools
        ];
        guiPath = lib.makeBinPath [
          xdg-utils
          desktop-file-utils
        ];
      in
      ''
                runHook preInstall

                mv usr $out

                # The daemon resolves /proc/self/exe and uses its directory as the
                # working directory for config, logs, and wireguard tools.
                # Since the nix store is read-only, create a wrapper that copies
                # the daemon binary to a writable state directory at runtime.
                mv $out/lib/wifiman-desktop/wifiman-desktopd{,.bin}

                cat > $out/lib/wifiman-desktop/wifiman-desktopd <<'WRAPPER'
        #!/usr/bin/env bash
        set -euo pipefail
        STATE_DIR="''${WIFIMAN_STATE_DIR:-/var/lib/wifiman-desktop}"
        STORE_LIB="@storeLib@"
        mkdir -p "$STATE_DIR"
        install -m 755 "$STORE_LIB/wifiman-desktopd.bin" "$STATE_DIR/wifiman-desktopd"
        for f in .env .env.development .env.staging wg wg-quick wireguard-go wg_report.sh; do
          [ -e "$STORE_LIB/$f" ] && ln -sf "$STORE_LIB/$f" "$STATE_DIR/$f"
        done
        export PATH="@runtimePath@:$PATH"
        exec "$STATE_DIR/wifiman-desktopd" "$@"
        WRAPPER
                chmod +x $out/lib/wifiman-desktop/wifiman-desktopd

                substituteInPlace $out/lib/wifiman-desktop/wifiman-desktopd \
                  --replace-fail "@storeLib@" "$out/lib/wifiman-desktop" \
                  --replace-fail "@runtimePath@" "${runtimePath}"

                # Wrap the desktop GUI binary with required runtime dependencies
                wrapProgram $out/bin/wifiman-desktop \
                  --prefix PATH : ${guiPath} \
                  --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]} \
                  --set GIO_EXTRA_MODULES "${glib-networking}/lib/gio/modules" \
                  --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
                  --prefix XDG_DATA_DIRS : "$out/share"

                # Make daemon wrapper accessible from bin/
                ln -sf ../lib/wifiman-desktop/wifiman-desktopd $out/bin/wifiman-desktopd

                # Fix the bundled systemd service file path
                substituteInPlace $out/lib/wifiman-desktop/wifiman-desktop.service \
                  --replace-fail '"/usr/lib/wifiman-desktop/wifiman-desktopd"' "$out/bin/wifiman-desktopd"

                runHook postInstall
      '';

    meta = with lib; {
      homepage = "https://ui.com/download/app/wifiman-desktop";
      description = "WiFiman Desktop - WiFi analysis and Teleport VPN";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      maintainers = with maintainers; [ turtton ];
    };
  });
}
