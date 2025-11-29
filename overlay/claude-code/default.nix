inputs: self: prev: {
  claude-code = self.callPackage (
    {
      additionalPaths ? [ ],
    }:
    let
      original = inputs.claude-code-overlay.packages.${prev.stdenv.hostPlatform.system}.default.override {
        inherit additionalPaths;
      };
      wrapper-script = self.substitute {
        src = ./claude-code-profile-manager.sh;
        substitutions = [
          "--subst-var-by"
          "claude-code"
          "${original}/bin/claude"
        ];
      };
      claude-code-wrapper = self.writeShellScriptBin "claude-code-wrapper" (
        builtins.readFile wrapper-script
      );

    in
    self.symlinkJoin {
      inherit (original) pname version;
      name = "${original.name}-wrapped";
      paths = [
        original
        claude-code-wrapper
      ];
      postBuild = ''
        mv "$out/bin/claude" "$out/bin/claude-original"
        mv "$out/bin/claude-code-wrapper" "$out/bin/claude"
      '';
      meta = original.meta;
    }
  ) { };
}
