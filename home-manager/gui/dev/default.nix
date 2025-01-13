{ pkgs, ... }: {
  imports = [
    ./idea
    ./vscode.nix
  ];
  home.packages = (with pkgs; [
    insomnia # RestAPI dev	tool
    remmina # Remote desktop client
    gitify
    drawio
  ]) ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux [
    pkgs.unityhub
  ];
}
