{ pkgs, ... }:
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
      remmina
    ]
    ++ lib.optionals hostPlatform.isLinux [
      unityhub
      isaacsim-webrtc-streaming-client
    ];
}
