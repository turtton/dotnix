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
    android-studio
    # basically should not use toolbox because of issues(https://github.com/NixOS/nixpkgs/issues/240444) but useful to preview IDE 
    jetbrains-toolbox
  ] ++ (map (ide: (jetbrains.plugins.addPlugins ide plugins)) ides);
}