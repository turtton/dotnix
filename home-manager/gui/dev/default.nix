{ pkgs, hostPlatform, ... }:
{
  imports =
    (
      if hostPlatform.isLinux then
        [
          ./vscode.nix
        ]
      else
        [ ]
    )
    ++ [
      ./idea
      ./ai.nix
    ];
  home.packages =
    with pkgs;
    [
      hoppscotch # WebAPI dev	tool
      gitify
      drawio
      lens
    ]
    ++ lib.optionals hostPlatform.isLinux [
      isaacsim-webrtc-streaming-client
    ];
  programs.zed-editor.enable = true;
}
