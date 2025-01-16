{ pkgs, ... }: {
  imports = [
    ./idea
    ./vscode.nix
  ];
  home.packages = with pkgs; [
    hoppscotch # WebAPI dev	tool
    gitify
    drawio
  ] ++ lib.optionals hostPlatform.isLinux [
    unityhub
    remmina # Remote desktop client TODO: https://github.com/NixOS/nixpkgs/pull/372613
  ];
}
