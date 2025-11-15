{ pkgs, hostPlatform, ... }:
{
  imports = [
    ./idea
    ./ai.nix
    ./vscode.nix
  ];
  home.packages =
    with pkgs;
    [
      hoppscotch # WebAPI dev	tool
      gitify
      drawio
    ]
    ++ lib.optionals hostPlatform.isLinux [
      isaacsim-webrtc-streaming-client
    ];
}
