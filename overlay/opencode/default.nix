inputs: self: prev: {
  opencode = inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default;
  opencode-latest =
    let
      opencode-latest-wrapper = self.writeShellScriptBin "opencode-latest-wrapper" (
        builtins.readFile ./opencode-latest-wrapper.sh
      );
    in
    self.symlinkJoin {
      name = "opencode-latest";
      paths = [ opencode-latest-wrapper ];
      postBuild = ''
        mv "$out/bin/opencode-latest-wrapper" "$out/bin/opencode-latest"
      '';
    };
}
