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
      blender
      isaacsim-webrtc-streaming-client
    ];
}
