inputs: self: prev: {
  opencode =
    let
      opencode =
        (inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default).overrideAttrs
          (old: {
            # Force channel to "latest" so opencode uses opencode.db instead of opencode-local.db.
            # Without this, Nix-built opencode defaults to channel="local" because OPENCODE_CHANNEL
            # is set to "local" in the upstream flake derivation.
            env = (old.env or { }) // {
              OPENCODE_CHANNEL = "latest";
            };
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
            gh
            gnupg
            coreutils
          ]
          ++ self.lib.optionals (!isDarwin) [
            self.bubblewrap
            self.tmux
            self.iproute2
            self.gnugrep
            self.gnused
          ];

        checkPhase = "";
        text =
          builtins.replaceStrings
            [
              "@opencode-dir@"
              "@tmux-conf@"
              "@quota-script@"
            ]
            [
              "${opencode}/bin"
              "${./tmux.conf}"
              "${./copilot-quota-poll.sh}"
            ]
            (builtins.readFile ./sandbox.sh);
      };

      # Wrapper script that uses sandbox by default
      opencode-wrapper-script = self.writeText "opencode-wrapper.sh" ''
        #!/usr/bin/env bash

        # Sandbox-first wrapper: all invocations run inside bubblewrap sandbox by default.
        # Set OPENCODE_NO_SANDBOX=1 to bypass the sandbox when needed.

        # Ensure the real opencode binary is in PATH
        export PATH="${opencode}/bin''${PATH:+:$PATH}"

        if [ -n "''${OPENCODE_NO_SANDBOX:-}" ]; then
          exec "${opencode}/bin/opencode" "$@"
        fi

        exec "${sandbox}/bin/opencode-sandbox" "$@"
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
