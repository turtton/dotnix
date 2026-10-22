self: prev:
let
  inherit (self) lib;
  version = "1.5.25";
  releases = {
    aarch64-darwin = {
      platform = "macos-arm64";
      hash = "sha256-W9SJaGjiFPa96qYA3I35chUBF2aGiIUT60bTrVHSLYY=";
    };
    x86_64-darwin = {
      platform = "macos-x64";
      hash = "sha256-nsCvBva7vg1BbdjANyeTDtq+OXIDYc2hs5jDKtdpw3g=";
    };
    aarch64-linux = {
      platform = "linuxstatic-arm64";
      hash = "sha256-wYDyYvk18hZ6Y3mKsZVwny+S8cWBj9EZLAfCLBFp2d8=";
    };
    x86_64-linux = {
      platform = "linuxstatic-x64";
      hash = "sha256-NGKoOV+CKzkrfAgIxwEW75DheloUeeYEz8QdV7+9gnw=";
    };
  };
  release = releases.${self.stdenv.hostPlatform.system};
in
{
  safe-chain = self.stdenvNoCC.mkDerivation {
    pname = "safe-chain";
    inherit version;

    src = self.fetchurl {
      url = "https://github.com/AikidoSec/safe-chain/releases/download/${version}/safe-chain-${release.platform}";
      inherit (release) hash;
    };

    shellInit = self.fetchurl {
      url = "https://raw.githubusercontent.com/AikidoSec/safe-chain/${version}/packages/safe-chain/src/shell-integration/startup-scripts/init-posix.sh";
      hash = "sha256-GALt3RqHHNXcY52JS+PL8GlnmtujokqknLuQeGzOnh0=";
    };

    nativeBuildInputs = [ self.makeWrapper ];
    dontUnpack = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/libexec" "$out/scripts"
      # A binary under bin makes upstream store mutable state beside it.
      # libexec keeps config and caches in ~/.safe-chain instead.
      install -m755 "$src" "$out/libexec/safe-chain"
      makeWrapper "$out/libexec/safe-chain" "$out/bin/safe-chain" \
        --unset PKG_EXECPATH
      install -m644 "$shellInit" "$out/scripts/init-posix.sh"

      runHook postInstall
    '';

    meta = {
      description = "Block malicious npm and PyPI packages before installation";
      homepage = "https://github.com/AikidoSec/safe-chain";
      license = lib.licenses.agpl3Plus;
      platforms = builtins.attrNames releases;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      mainProgram = "safe-chain";
    };
  };
}
