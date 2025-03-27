gen: self: prev:
{
  beutl = with self; buildDotnetModule {
    inherit (gen) src;
    pname = "Beutl";
    version = lib.removePrefix "v" gen.version;

    projectFile = "src/Beutl/Beutl.csproj";
    nugetDeps = ./deps.json;
    mapNuGetDependencies = true;
    # Sometimes fails with "The process cannot access the file because it is being used by another process."
    enableParallelBuilding = false;

    buildInputs = [ ffmpeg ];
    runtimeDeps = [ ffmpeg fontconfig ];

    dotnet-sdk = dotnetCorePackages.sdk_9_0-bin;
    dotnet-runtime = dotnetCorePackages.runtime_9_0-bin;

    selfContained = true;
    dotnetInstallFlags = [
      "--framework net9.0"
      "-p:IncludeSourceRevisionInInformationalVersion=false"
    ];

    patches = [
      ./0001-fix-Resolve-fc-match-path-dynamically-on-Linux.patch
    ];

    #executables = [ "Beutl" "Beutl.ExceptionHandler" "Beutl.PackageTools.UI" "Beutl.WaitingDialog" ];

    meta = with lib; {
      description = "Cross-platform video editing (compositing) software.";
      homepage = "https://docs.beutl.beditor.net";
      license = with licenses; [ gpl3 ];
    };
  };
}
