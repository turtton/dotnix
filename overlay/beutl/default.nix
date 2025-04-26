{ beutl, beutl-native-deps }:
self: prev:
let
  runtime-libraries = self.stdenv.mkDerivation {
    name = "runtime-libraries";
    src = beutl-native-deps.src;
    installPhase = ''
      mkdir -p $out/lib
      cp -r $src/linux-x64/* $out/lib
    '';
    outputs = [ "out" ];
  };
in
{
  beutl =
    with self;
    buildDotnetModule {
      inherit (beutl) src;
      pname = "Beutl";
      version = lib.removePrefix "v" beutl.version;

      projectFile = "src/Beutl/Beutl.csproj";
      nugetDeps = ./deps.json;
      mapNuGetDependencies = true;

      buildInputs = [ ffmpeg_6-full ];
      # Requires https://github.com/shimat/opencvsharp but not available in nixpkgs
      runtimeDeps = [
        ffmpeg_6-full
        fontconfig
        glfw
        opencv
        runtime-libraries
      ];

      dotnet-sdk = dotnetCorePackages.sdk_9_0-bin;
      dotnet-runtime = dotnetCorePackages.runtime_9_0-bin;

      selfContained = true;
      dotnetInstallFlags = [
        "--framework net9.0"
        "-p:IncludeSourceRevisionInInformationalVersion=false"
      ];

      #executables = [ "Beutl" "Beutl.ExceptionHandler" "Beutl.PackageTools.UI" "Beutl.WaitingDialog" ];
      FFMPEG_PATH = "${ffmpeg_6-full}/bin/ffmpeg";

      meta = with lib; {
        description = "Cross-platform video editing (compositing) software.";
        homepage = "https://docs.beutl.beditor.net";
        license = with licenses; [ gpl3 ];
      };
    };
}
