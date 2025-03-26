gen: self: prev:
{
  beutl = with self; buildDotnetModule {
    inherit (gen) src;
    pname = "Beutl";
    version = lib.removePrefix "v" gen.version;

    projectFile = "Beutl.slnx";
    nugetDeps = ./beutl.json;
    mapNuGetDependencies = true;
    #useAppHost = false;
    # Sometimes fails with "The process cannot access the file because it is being used by another process."
    enableParallelBuilding = false;

    buildInputs = [ ffmpeg ];
    runtimeDeps = [ ffmpeg mono fontconfig ];

    dotnet-sdk = dotnetCorePackages.sdk_9_0-bin;
    dotnet-runtime = dotnetCorePackages.runtime_9_0-bin;

    dotnetInstallFlags = [
      "-p:RuntimeIdentifiers=linux-x64"
      "-p:IncludeSourceRevisionInInformationalVersion=false"
      "--framework net9.0"
    ];

    #executables = [ "Beutl" "Beutl.ExceptionHandler" "Beutl.PackageTools.UI" "Beutl.WaitingDialog" ];

    meta = with lib; {
      description = "Cross-platform video editing (compositing) software.";
      homepage = "https://docs.beutl.beditor.net";
      license = with licenses; [ gpl3 ];
    };
  };
}
