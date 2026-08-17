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
      # WebAPI dev tool
      hoppscotch
      bruno

      gitify
      lens
      dbeaver-bin
    ]
    ++ lib.optionals hostPlatform.isLinux [
      drawio # also works darwin but I do not use it
      isaacsim-webrtc-streaming-client
    ];
  programs.zed-editor.enable = true;
}
