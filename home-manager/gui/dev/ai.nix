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
      gemini-cli
      codex
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code.override {
      additionalPaths = [
        "${config.home.homeDirectory}/.local/bin"
      ];
    };
  };
}
