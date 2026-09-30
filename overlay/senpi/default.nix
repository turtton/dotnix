inputs: self: prev:
let
  original = self.writeShellScriptBin "senpi" ''
    export OMO_CODING_AGENT_DIR="''${OMO_CODING_AGENT_DIR:-$HOME/.senpi/agent}"
    exec "${self.omo-native}/bin/omo" "$@"
  '';
  isDarwin = prev.stdenv.hostPlatform.isDarwin;

  herdrChild = import ./herdr-child.nix { inherit (self) writeText writeShellScript; };

  sandbox = self.writeShellApplication {
    name = "senpi-sandbox";
    runtimeInputs =
      with self;
      [
        jq
        git
        gh
        gnupg
        coreutils
        curl
      ]
      ++ self.lib.optionals (!isDarwin) [
        self.bubblewrap
        self.gnugrep
        self.gnused
      ];
    checkPhase = "";
    text =
      builtins.replaceStrings
        [ "@senpi-dir@" "@child-wrapper@" ]
        [
          "${original}/bin"
          "${herdrChild}"
        ]
        (builtins.readFile (if isDarwin then ./sandbox-darwin.sh else ./sandbox.sh));
  };

  sandboxShim = self.writeShellScript "senpi-sandbox-shim.sh" (
    builtins.replaceStrings [ "@senpi-sandbox@" ] [ "${sandbox}/bin/senpi-sandbox" ] (
      builtins.readFile ./senpi-sandbox-shim.sh
    )
  );

  launcher-tmux = self.writeShellApplication {
    name = "senpi-tmux";
    runtimeInputs = with self; [
      tmux
      curl
      jq
      gh
      gnused
      coreutils
    ];
    checkPhase = "";
    text =
      builtins.replaceStrings
        [
          "@senpi-dir@"
          "@tmux-conf@"
          "@quota-script@"
          "@openai-quota-script@"
          "@crof-quota-script@"
          "@openrouter-quota-script@"
          "@claude-quota-script@"
          "@kimi-quota-script@"
        ]
        [
          "${original}/bin"
          "${./legacy/tmux.conf}"
          "${../opencode/legacy/copilot-quota-poll.sh}"
          "${../opencode/legacy/openai-quota-poll.sh}"
          "${../opencode/legacy/crof-quota-poll.sh}"
          "${../opencode/legacy/openrouter-quota-poll.sh}"
          "${../opencode/legacy/claude-quota-poll.sh}"
          "${../opencode/legacy/kimi-quota-poll.sh}"
        ]
        (builtins.readFile ./legacy/senpi-tmux.sh);
  };

  launcher-herdr = self.writeShellApplication {
    name = "senpi-herdr";
    runtimeInputs =
      with self;
      [
        herdr
        curl
        jq
        gh
        gnused
        coreutils
      ]
      ++ self.lib.optionals (!isDarwin) [
        util-linux
      ];
    checkPhase = "";
    text =
      builtins.replaceStrings
        [ "@senpi-dir@" "@child-wrapper@" ]
        [
          "${original}/bin"
          "${sandboxShim}"
        ]
        (builtins.readFile ./senpi-herdr.sh);
  };

  launcher = self.writeShellScriptBin "senpi" ''
    if [[ -n ''${SENPI_NO_SANDBOX:-} ]]; then
      exec "${senpi-bare}/bin/senpi-bare" "$@"
    elif [[ -n ''${HERDR_ENV:-} && -z ''${SENPI_HERDR_CHILD:-} ]]; then
      exec "${launcher-herdr}/bin/senpi-herdr" "$@"
    else
      exec "${sandbox}/bin/senpi-sandbox" "$@"
    fi
  '';

  senpi-bare = self.writeShellScriptBin "senpi-bare" ''
    exec "${original}/bin/senpi" "$@"
  '';

  senpiOverlay = inputs.senpi.overlays.default self prev;
in
senpiOverlay
// {
  senpi = self.symlinkJoin {
    inherit (self.omo-native) pname version;
    name = "${self.omo-native.name}-wrapped";
    paths = [
      launcher
      launcher-tmux
      launcher-herdr
      senpi-bare
      sandbox
    ];
    postBuild = ''
      ln -s "$out/bin/senpi" "$out/bin/pi"
    '';
    meta = self.omo-native.meta // {
      mainProgram = "senpi";
    };
  };
}
