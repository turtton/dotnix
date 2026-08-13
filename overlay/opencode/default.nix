inputs: self: prev: {
  opencode =
    let
      # original = inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default;
      original = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.opencode;
      opencode = original.overrideAttrs (old: {
        # Force channel to "latest" so opencode uses opencode.db instead of opencode-local.db.
        # Without this, Nix-built opencode defaults to channel="local" because OPENCODE_CHANNEL
        # is set to "local" in the upstream flake derivation.
        env = (old.env or { }) // {
          OPENCODE_CHANNEL = "latest";
        };
      });
      isDarwin = prev.stdenv.isDarwin;

      mkQuotaPoller =
        name:
        self.writeText name (
          builtins.replaceStrings [ "__QUOTA_REPORT__" ] [ "${./quota-report.sh}" ] (
            builtins.readFile (./. + "/${name}")
          )
        );

      quotaPollers = {
        copilot = mkQuotaPoller "copilot-quota-poll.sh";
        openai = mkQuotaPoller "openai-quota-poll.sh";
        crof = mkQuotaPoller "crof-quota-poll.sh";
        openrouter = mkQuotaPoller "openrouter-quota-poll.sh";
        claude = mkQuotaPoller "claude-quota-poll.sh";
        kimi = mkQuotaPoller "kimi-quota-poll.sh";
      };

      sandboxChild = self.writeText "opencode-child-wrapper.sh" (
        builtins.replaceStrings
          [
            "@quota-script@"
            "@openai-quota-script@"
            "@crof-quota-script@"
            "@openrouter-quota-script@"
            "@claude-quota-script@"
            "@kimi-quota-script@"
            "@quota-report@"
          ]
          [
            "${quotaPollers.copilot}"
            "${quotaPollers.openai}"
            "${quotaPollers.crof}"
            "${quotaPollers.openrouter}"
            "${quotaPollers.claude}"
            "${quotaPollers.kimi}"
            "${./quota-report.sh}"
          ]
          (builtins.readFile ./child-wrapper.sh)
      );

      sandboxChildDarwin = self.writeText "opencode-child-wrapper-darwin.sh" (
        builtins.replaceStrings
          [
            "@quota-script@"
            "@openai-quota-script@"
            "@crof-quota-script@"
            "@openrouter-quota-script@"
            "@kimi-quota-script@"
            "@quota-report@"
          ]
          [
            "${quotaPollers.copilot}"
            "${quotaPollers.openai}"
            "${quotaPollers.crof}"
            "${quotaPollers.openrouter}"
            "${quotaPollers.kimi}"
            "${./quota-report.sh}"
          ]
          (builtins.readFile ./child-wrapper-darwin.sh)
      );

      sandbox = self.writeShellApplication {
        name = "opencode-sandbox";
        runtimeInputs =
          with self;
          [
            jq
            herdr
            git
            gh
            gnupg
            coreutils
            tmux
            curl
          ]
          ++ self.lib.optionals (!isDarwin) [
            self.bubblewrap
            self.iproute2
            self.gnugrep
            self.gnused
          ];

        checkPhase = "";
        text =
          builtins.replaceStrings
            [
              "@opencode-dir@"
              "@child-wrapper@"
              "@tmux-conf@"
              "@quota-script@"
              "@openai-quota-script@"
              "@crof-quota-script@"
              "@openrouter-quota-script@"
              "@claude-quota-script@"
              "@kimi-quota-script@"
              "@quota-report@"
            ]
            [
              "${opencode}/bin"
              "${if isDarwin then sandboxChildDarwin else sandboxChild}"
              "${./tmux.conf}"
              "${quotaPollers.copilot}"
              "${quotaPollers.openai}"
              "${quotaPollers.crof}"
              "${quotaPollers.openrouter}"
              "${quotaPollers.claude}"
              "${quotaPollers.kimi}"
              "${./quota-report.sh}"
            ]
            (builtins.readFile (if isDarwin then ./sandbox-darwin.sh else ./sandbox.sh));
      };

      legacyAsset = name: self.writeText "legacy-${name}" (builtins.readFile (./legacy + "/${name}"));

      sandbox-legacy = self.writeShellApplication {
        name = "opencode-tmux";
        runtimeInputs =
          with self;
          [
            jq
            git
            gh
            gnupg
            coreutils
            tmux
            curl
          ]
          ++ self.lib.optionals (!isDarwin) [
            self.bubblewrap
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
              "@openai-quota-script@"
              "@crof-quota-script@"
              "@openrouter-quota-script@"
              "@claude-quota-script@"
              "@kimi-quota-script@"
            ]
            [
              "${opencode}/bin"
              "${legacyAsset "tmux.conf"}"
              "${legacyAsset "copilot-quota-poll.sh"}"
              "${legacyAsset "openai-quota-poll.sh"}"
              "${legacyAsset "crof-quota-poll.sh"}"
              "${legacyAsset "openrouter-quota-poll.sh"}"
              "${legacyAsset "claude-quota-poll.sh"}"
              "${legacyAsset "kimi-quota-poll.sh"}"
            ]
            (builtins.readFile (if isDarwin then ./legacy/sandbox-darwin.sh else ./legacy/sandbox.sh));
      };

      # Wrapper script that uses sandbox by default
      opencode-wrapper-script = self.writeText "opencode-wrapper.sh" ''
        #!/usr/bin/env bash

        # Sandbox-first wrapper: all invocations run inside sandbox by default.
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
    self.symlinkJoin {
      inherit (opencode) pname version;
      name = "${opencode.name}-wrapped";
      paths = [
        opencode-wrapper
        sandbox-legacy
      ];
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
