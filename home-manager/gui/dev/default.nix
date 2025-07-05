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
      # https://github.com/NixOS/nixpkgs/issues/418451
      # unityhub
      isaacsim-webrtc-streaming-client
    ];
}
