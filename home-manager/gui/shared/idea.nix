{pkgs, ...}: let 
  ides = with pkgs.jetbrains; [
    idea-ultimate
    webstorm
    rust-rover
  ];
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json
  plugins = [
    "ideavim"
    "nixidea"
    "github-copilot"
  ];
in  {
  home.packages = with pkgs; [
    jetbrains-toolbox
  ] ++ (map (ide: (jetbrains.plugins.addPlugins ide plugins)) ides);
}