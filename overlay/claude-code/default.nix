inputs: self: prev: {
  claude-code =
    let
      claude-code = inputs.claude-code-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
      sandboxDeps = self.lib.optionals prev.stdenv.hostPlatform.isLinux [
        self.bubblewrap
        self.socat
      ];
      claude-wrapper-script = self.substitute {
        src = ./claude-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "claude-code-dir"
          "${claude-code}/bin"
          "--subst-var-by"
          "path-prefix"
          (self.lib.makeBinPath ([ claude-code ] ++ sandboxDeps))
        ];
      };
      claude-wrapper = self.writeShellScriptBin "claude-wrapper" (
        builtins.readFile claude-wrapper-script
      );
      claude-latest-wrapper-script = self.substitute {
        src = ./claude-latest-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "sandbox-path"
          (self.lib.makeBinPath sandboxDeps)
        ];
      };
      claude-latest-wrapper = self.writeShellScriptBin "claude-latest-wrapper" (
        builtins.readFile claude-latest-wrapper-script
      );
      claude-profile = self.writeShellScriptBin "claude-profile" (
        builtins.readFile ./claude-code-profile-manager.sh
      );
    in
    self.symlinkJoin {
      inherit (claude-code) pname version;
      name = "${claude-code.name}-wrapped";
      paths = [
        claude-wrapper
        claude-latest-wrapper
        claude-profile
      ];
      postBuild = ''
        mv "$out/bin/claude-wrapper" "$out/bin/claude"
        mv "$out/bin/claude-latest-wrapper" "$out/bin/claude-latest"
      '';
      meta = claude-code.meta // {
        mainProgram = "claude";
      };
    };
}
