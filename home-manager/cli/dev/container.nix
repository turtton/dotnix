{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    helm
    talosctl
  ];
}
