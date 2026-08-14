inputs: self: prev:
let
  original = inputs.senpi.packages.${prev.stdenv.hostPlatform.system}.default;
  isDarwin = prev.stdenv.isDarwin;

  herdrChild = import ./herdr-child.nix { inherit (self) writeText writeShellScript; };

  sandbox = self.writeShellApplication {
    name = "senpi-sandbox";
    runtimeInputs = with self; [
      jq
      git
      gh
      gnupg
      coreutils
      curl
      bubblewrap
      gnugrep
      gnused
    ];
    checkPhase = "";
    text =
      builtins.replaceStrings
        [ "@senpi-dir@" "@child-wrapper@" ]
        [
          "${original}/bin"
          "${herdrChild}"
        ]
        (builtins.readFile ./sandbox.sh);
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
{
  senpi = self.symlinkJoin {
    inherit (original) pname version;
    name = "${original.name}-wrapped";
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
    meta = original.meta // {
      mainProgram = "senpi";
    };
  };

  # packages.*.omo-senpi は senpi-flake 内部の config 無し pkgs で評価済みのため、
  # unfree チェックが消費側の allowUnfree を無視して失敗する。overlays.default 経由で
  # 自側 pkgs から構築する必要がある。
  omo-senpi = senpiOverlay.omo-senpi;

  # senpiOverlay.omo-cli は comment-checker を fixed point から auto-fill する前提の
  # ため、attr 選り抜きでは必須引数が欠落して評価失敗する。直接 callPackage して明示する。
  omo-cli = self.callPackage "${inputs.senpi}/omo-cli.nix" {
    comment-checker = senpiOverlay.comment-checker;
  };
}
