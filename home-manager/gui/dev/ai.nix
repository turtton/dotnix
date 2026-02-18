{
  pkgs,
  hostPlatform,
  config,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      codex-latest
      opencode-latest
      llm-agents.codex
      opencode
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
  programs.claude-code = {
    enable = true;
  };
}
