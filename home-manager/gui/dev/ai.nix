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
      llm-agents.codex
      llm-agents.opencode
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
  programs.claude-code = {
    enable = true;
  };
}
