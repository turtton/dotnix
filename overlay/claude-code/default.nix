inputs: self: prev: {
  claude-code =
    let
      claude-code = inputs.claude-code-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
      sandbox = self.writeShellApplication {
        name = "claude-sandbox";
        runtimeInputs = with self; [
          bubblewrap
          jq
          git
          gnupg
          coreutils
        ];
        checkPhase = "";
        text = builtins.replaceStrings [ "@claude-code-dir@" ] [ "${claude-code}/bin" ] (
          builtins.readFile ./sandbox.sh
        );
      };
      claude-wrapper-script = self.substitute {
        src = ./claude-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "sandbox"
          "${sandbox}/bin/claude-sandbox"
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
          "sandbox"
          "${sandbox}/bin/claude-sandbox"
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
