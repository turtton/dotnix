inputs: self: prev: {
  claude-code = self.callPackage (
    {
      additionalPaths ? [ ],
    }:
    let
      original = inputs.claude-code-overlay.packages.${prev.stdenv.hostPlatform.system}.default.override {
        inherit additionalPaths;
      };
      claude-wrapper-script = self.substitute {
        src = ./claude-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "claude-code"
          "${original}/bin/claude"
        ];
      };
      claude-wrapper = self.writeShellScriptBin "claude-wrapper" (
        builtins.readFile claude-wrapper-script
      );
      claude-profile = self.writeShellScriptBin "claude-profile" (
        builtins.readFile ./claude-code-profile-manager.sh
      );
    in
    self.symlinkJoin {
      inherit (original) pname version;
      name = "${original.name}-wrapped";
      paths = [
        original
        claude-wrapper
        claude-profile
      ];
      postBuild = ''
        rm "$out/bin/claude"
        mv "$out/bin/claude-wrapper" "$out/bin/claude"
      '';
      meta = original.meta;
    }
  ) { };
}
