inputs: final: prev:
let
  inherit (final) lib;
  affectedRevision = "b1332396df6e880d7e3b6b451c6a74132ce8cf66";
  kernelModules = lib.getOutput "modules" prev.cachyosKernels.linuxPackages-cachyos-latest.kernel;
  certificateMerge = ''
    cp --no-preserve=mode,ownership --remove-destination \
          -- "$(readlink -f modules.cer)" modules.cer
        sed "1,$(wc -l < modules.order)d; s/\.ko.*/.ko.cer/" modules.dep \
            | xargs -d'\n' cat >> modules.cer
  '';
in
{
  # https://github.com/xddxdd/nix-cachyos-kernel/issues/111
  aggregateModules =
    modules:
    let
      aggregated = prev.aggregateModules modules;
    in
    if
      (inputs.nix-cachyos-kernel.rev or null) == affectedRevision
      && builtins.any (module: toString module == toString kernelModules) modules
    then
      aggregated.overrideAttrs (old: {
        postBuild =
          assert lib.hasInfix certificateMerge old.postBuild;
          lib.replaceStrings
            [ certificateMerge ]
            [
              ("if test -e modules.cer || test -L modules.cer; then\n    " + certificateMerge + "    fi\n")
            ]
            old.postBuild;
      })
    else
      aggregated;
}
