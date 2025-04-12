{ pkgs, ... }:
let
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json
  plugins = [
    "github-copilot"
    "ideavim"
    "nixidea"
  ];
  applyPlugins = ide: with pkgs; (jetbrains.plugins.addPlugins ide plugins);
  ides = with pkgs.jetbrains; [
    idea-ultimate
    webstorm
    rust-rover
    datagrip
    pycharm-professional
    clion
    rider
  ];
in
{
  home.packages =
    with pkgs;
    if hostPlatform.isLinux then
      [
        android-studio
        # basically should not use toolbox because of issues(https://github.com/NixOS/nixpkgs/issues/240444) but useful to preview IDE
        jetbrains-toolbox
      ]
      ++ (map (ide: (applyPlugins ide)) ides)
    else
      ides;
  home.file.".ideavimrc".source = ./ideavimrc;
}
