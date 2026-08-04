gen: self: prev: {
  omniwm =
    with self;
    stdenvNoCC.mkDerivation {
      inherit (gen) pname version src;

      # unzip だと拡張属性が落ちて notarize 署名が壊れ、Accessibility 権限を付与できない
      nativeBuildInputs = [ libarchive ];
      dontUnpack = true;

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/Applications" "$out/bin"
        bsdtar -xf "$src" -C "$out/Applications"
        ln -s "$out/Applications/OmniWM.app/Contents/MacOS/omniwmctl" "$out/bin/omniwmctl"

        runHook postInstall
      '';

      meta = {
        description = "macOS tiling window manager inspired by Niri and Hyprland";
        homepage = "https://github.com/BarutSRB/OmniWM";
        license = lib.licenses.gpl2Only;
        platforms = lib.platforms.darwin;
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        mainProgram = "omniwmctl";
      };
    };
}
