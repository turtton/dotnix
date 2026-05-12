{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    talosctl
    argocd
    kubeseal
  ];
}
