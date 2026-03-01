inputs: self: prev: {
  opencode =
    let
      opencode =
        (inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default).overrideAttrs
          (old: {
            nativeBuildInputs = map (dep: if (dep.pname or "") == "bun" then self.bun else dep) (
              old.nativeBuildInputs or [ ]
            );
          });
      isDarwin = prev.stdenv.isDarwin;

      # Sandbox script (Linux only)
      sandbox = self.writeShellApplication {
        name = "opencode-sandbox";
        runtimeInputs =
          with self;
          [
            jq
            git
            gnupg
            coreutils
          ]
          ++ self.lib.optionals (!isDarwin) [ self.bubblewrap ];
        checkPhase = "";
        text = builtins.replaceStrings [ "@opencode-dir@" ] [ "${opencode}/bin" ] (
          builtins.readFile ./sandbox.sh
        );
      };

      # Wrapper script that uses sandbox by default
      opencode-wrapper-script = self.writeText "opencode-wrapper.sh" ''
        #!/usr/bin/env bash

        # Thin wrapper that routes to sandbox when no args, or to real opencode when args are given.

        # Ensure the real opencode binary is in PATH
        export PATH="${opencode}/bin''${PATH:+:$PATH}"

        # Determine target: no args → sandbox, with args → real opencode
        if [ $# -eq 0 ]; then
          target="${sandbox}/bin/opencode-sandbox"
        else
          target="${opencode}/bin/opencode"
        fi

        exec "$target" "$@"
      '';

      opencode-wrapper = self.writeShellScriptBin "opencode-wrapper" (
        builtins.readFile opencode-wrapper-script
      );
    in
    if isDarwin then
      opencode # Darwin doesn't support bubblewrap, use original binary
    else
      self.symlinkJoin {
        inherit (opencode) pname version;
        name = "${opencode.name}-wrapped";
        paths = [ opencode-wrapper ];
        postBuild = ''
          mv "$out/bin/opencode-wrapper" "$out/bin/opencode"
        '';
        meta = opencode.meta // {
          mainProgram = "opencode";
        };
      };

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
