{ pkgs, ... }:
let
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json
  plugins = [
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
        # basically should not use toolbox because of issues(https://github.com/NixOS/nixpkgs/issues/240444) but useful to preview IDE
        jetbrains-toolbox
      ]
      # Failed to build....
      #++ (map (ide: (applyPlugins ide)) ides)
      ++ ides
    else
      ides;
  home.file.".ideavimrc".source = ./ideavimrc;
}
