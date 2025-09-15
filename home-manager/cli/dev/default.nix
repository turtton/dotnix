{ pkgs, hostPlatform, ... }:
let
  stack-wrapped = pkgs.symlinkJoin {
    name = "stack";
    paths = [ pkgs.stack ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/stack \
        --add-flags "\
          --no-nix \
          --system-ghc \
          --no-install-ghc \
        "
    '';
  };
in
{
  imports = [
    ./cargo.nix
    ./container.nix
  ];
  home.packages =
    with pkgs;
    [
      gcc
      go
      nodejs-slim
      # nodePackages.wrangler
      deno
      bun
      # python312 conflicts on os/wm/plasma5.nix#environment.systemPackages.python3Full
      uv
      jdk21

      kotlin
      ktlint
      act

      # Haskell
      ghc

      # Git Repository Management
      siketyan-ghr
    ]
    ++ pkgs.lib.optionals hostPlatform.isLinux [
      stack-wrapped
    ];
  programs.zsh.initContent = ''
    source <(ghr shell)
    source <(ghr shell --completion bash)
  '';
}
