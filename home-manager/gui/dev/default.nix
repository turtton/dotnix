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

      # window sharings
      remmina
    ]
    ++ lib.optionals hostPlatform.isLinux [
      isaacsim-webrtc-streaming-client
      parsec-bin
    ];
}
