{ pkgs, ... }: {
  imports = [
    ./idea
    ./vscode.nix
  ];
  home.packages = with pkgs; [
    unityhub
    blockbench-electron
    insomnia # RestAPI dev	tool
    remmina # Remote desktop client
    gitify
    drawio
  ];
}
