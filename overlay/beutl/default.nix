gen: self: prev: {
  beutl = with self; buildDotnetModule {
    inherit (gen) src;
    pname = "Beutl";
    version = lib.removePrefix "v" gen.version;

    projectFile = "src/Beutl/Beutl.csproj";
    nugetDeps = ./deps.json;
    mapNuGetDependencies = true;

    buildInputs = [ ffmpeg_6-full ];
	# Requires https://github.com/shimat/opencvsharp but not available in nixpkgs
    runtimeDeps = [ ffmpeg_6-full fontconfig glfw opencv ];

    dotnet-sdk = dotnetCorePackages.sdk_9_0-bin;
    dotnet-runtime = dotnetCorePackages.runtime_9_0-bin;

	selfContained = true;
    dotnetInstallFlags = [
      "--framework net9.0"
      "-p:IncludeSourceRevisionInInformationalVersion=false"
    ];

    patches = [
      ./0001-fix-Resolve-fc-match-path-dynamically-on-Linux.patch
	  ./0002-fix-Append-additinal-library-path-for-linux.patch
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
