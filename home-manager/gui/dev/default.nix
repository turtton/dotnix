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
  # wait until libxml2 is fixed
  # https://nixpkgs-tracker.ocfox.me/?pr=421740
  nixpkgs.config.permittedInsecurePackages = [
    "libxml2-2.13.8"
  ];
}
