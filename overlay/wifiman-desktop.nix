self: prev: with self; {
  wifiman-desktop = stdenv.mkDerivation (finalAttrs: {
    pname = "wi-fiman-desktop";
    name = "wifiman-desktop";
    version = "1.1.3";

    # see https://community.ui.com/releases / https://www.ui.com/download/unifi
    src = fetchurl {
      url = "https://desktop.wifiman.com/wifiman-desktop-${finalAttrs.version}-amd64.deb";
      hash = "sha256-y//hyqymtgEdrKZt3milTb4pp+TDEDQf6RehYgDnhzA=";
    };

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
    ];

    buildInputs = [
      systemd
      webkitgtk_4_0
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      ls -la usr/
      mv -v usr/{bin,lib,share} $out

      runHook postInstall
    '';

    passthru.tests = { inherit (nixosTests) unifi; };

    meta = with lib; {
      # Build passed, but the app is not working properly
      broken = true;
      homepage = "https://ui.com/download/app/wifiman-desktop";
      description = "Powerful WiFi Insights";
      sourceProvenance = with sourceTypes; [ binaryBytecode ];
      license = licenses.unfree;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maintainers = with maintainers; [
        turtton
      ];
    };
  });
}
