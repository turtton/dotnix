{
  pkgs,
  lib,
  hostPlatform,
  isWsl,
  ...
}:
{
  imports = [
    ./opencode
  ];
  home.packages =
    with pkgs;
    [
      codex-latest
      opencode-latest
      llm-agents.codex
      rtk
      senpi
    ]
    ++ pkgs.lib.optionals (!isWsl) [
      opencode
    ];
  programs.claude-code = {
    enable = true;
  };
  home.activation.rtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe pkgs.rtk} init -g --opencode
  '';
}
