self: prev: {
  # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools
  isaacsim-webrtc-streaming-client =
    let
      version = "1.0.6";
      pname = "isaacsim-webrtc-streaming-client";
      src = self.fetchurl {
        url = "https://download.isaacsim.omniverse.nvidia.com/isaacsim-webrtc-streaming-client-${version}-linux-x64.AppImage";
        hash = "sha256-BaIi18HL23x4M3ZE9Q+PrW2iLkh34wjUhwpr4o2vwW0=";
      };
      appimageContents = self.appimageTools.extract { inherit pname version src; };
    in
    with self; appimageTools.wrapType2 rec {
      inherit pname version src;

      extraPkgs = pkgs: [ pkgs.at-spi2-core ];

      extraInstallCommands = ''
        #mv $out/bin/${pname}-${version} $out/bin/${pname}
        ls ${appimageContents}
        mkdir -p $out/share/applications
        install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
        mkdir -p $out/share/icons/hicolor/512x512/apps
        install -m 444 -D ${appimageContents}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png
        substituteInPlace $out/share/applications/${pname}.desktop --replace-fail 'Exec=AppRun' 'Exec=${pname} --enable-wayland-ime --enable-features=UseOzonePlatform --ozone-platform=wayland'
      '';

      meta = with lib; {
        description = "NVIDIA Isaac Sim WebRTC Stream Client";
        homepage = "https://docs.isaacsim.omniverse.nvidia.com/latest/index.html";
        downloadPage = "https://docs.isaacsim.omniverse.nvidia.com/latest/installation/download.html#isaac-sim-latest-release";
        license = with licenses; [ unfree ];
      };
    };
}
