inputs: self: prev: {
  claude-code =
    let
      claude-code = inputs.claude-code-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
      original =
        inputs.claudebox.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs
          (old: {
            inherit claude-code;
          });
      claude-wrapper-script = self.substitute {
        src = ./claude-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "claudebox"
          "${original}/bin/claudebox"
          "--subst-var-by"
          "claude-code-dir"
          "${claude-code}/bin"
        ];
      };
      claude-wrapper = self.writeShellScriptBin "claude-wrapper" (
        builtins.readFile claude-wrapper-script
      );
      claude-latest-wrapper-script = self.substitute {
        src = ./claude-latest-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "claudebox"
          "${original}/bin/claudebox"
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
      name = "${original.name}-wrapped";
      paths = [
        original
        claude-wrapper
        claude-latest-wrapper
        claude-profile
      ];
      postBuild = ''
        mv "$out/bin/claude-wrapper" "$out/bin/claude"
        mv "$out/bin/claude-latest-wrapper" "$out/bin/claude-latest"
      '';
      meta = original.meta // {
        mainProgram = "claude";
      };
    };
}
