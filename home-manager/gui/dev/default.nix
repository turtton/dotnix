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

      # window sharings
      remmina
      parsec-bin
    ]
    ++ lib.optionals hostPlatform.isLinux [
      isaacsim-webrtc-streaming-client
    ];
}
