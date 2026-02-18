self: prev: {
  codex-latest =
    let
      codex-latest-wrapper = self.writeShellScriptBin "codex-latest-wrapper" (
        builtins.readFile ./codex-latest-wrapper.sh
      );
    in
    self.symlinkJoin {
      name = "codex-latest";
      paths = [ codex-latest-wrapper ];
      postBuild = ''
        mv "$out/bin/codex-latest-wrapper" "$out/bin/codex-latest"
      '';
    };
}
