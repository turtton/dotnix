inputs: self: prev: {
  claude-code =
    let
      claude-code = inputs.claude-code-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
      isDarwin = prev.stdenv.isDarwin;
      useWrapperSandbox = if isDarwin then "0" else "1";
      sandboxTarget = if isDarwin then "${claude-code}/bin/claude" else "${sandbox}/bin/claude-sandbox";
      sandbox = self.writeShellApplication {
        name = "claude-sandbox";
        runtimeInputs =
          with self;
          [
            jq
            git
            gnupg
            coreutils
          ]
          ++ self.lib.optionals (!isDarwin) [
            self.bubblewrap
          ];
        checkPhase = "";
        text = builtins.replaceStrings [ "@claude-code-dir@" ] [ "${claude-code}/bin" ] (
          builtins.readFile (if isDarwin then ./sandbox-darwin.sh else ./sandbox.sh)
        );
      };
      claude-wrapper-script = self.substitute {
        src = ./claude-wrapper.sh;
        substitutions = [
          "--subst-var-by"
          "sandbox"
          sandboxTarget
          "--subst-var-by"
          "claude-code-dir"
          "${claude-code}/bin"
          "--subst-var-by"
          "use-sandbox"
          useWrapperSandbox
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
          sandboxTarget
          "--subst-var-by"
          "use-sandbox"
          useWrapperSandbox
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
