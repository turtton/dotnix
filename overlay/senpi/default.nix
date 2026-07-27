inputs: self: prev:
let
  original = inputs.senpi.packages.${prev.stdenv.hostPlatform.system}.default;
  isDarwin = prev.stdenv.isDarwin;

  launcher = self.writeShellApplication {
    name = "senpi-tmux";
    runtimeInputs =
      with self;
      [
        tmux
        curl
        jq
        gh
        gnused
        coreutils
      ]
      # pi-sandbox 拡張の native バックエンドが bwrap と socat を必要とする (Linux)
      ++ self.lib.optionals (!isDarwin) [
        self.bubblewrap
        self.socat
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
}
