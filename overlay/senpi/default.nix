inputs: self: prev:
let
  original = inputs.senpi.packages.${prev.stdenv.hostPlatform.system}.default;

  launcher = self.writeShellApplication {
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
          "${./tmux.conf}"
          "${../opencode/copilot-quota-poll.sh}"
          "${../opencode/openai-quota-poll.sh}"
          "${../opencode/crof-quota-poll.sh}"
          "${../opencode/openrouter-quota-poll.sh}"
          "${../opencode/claude-quota-poll.sh}"
          "${../opencode/kimi-quota-poll.sh}"
        ]
        (builtins.readFile ./senpi-tmux.sh);
  };

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
      senpi-bare
    ];
    postBuild = ''
      mv "$out/bin/senpi-tmux" "$out/bin/senpi"
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
