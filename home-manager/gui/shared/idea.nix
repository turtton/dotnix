{pkgs, ...}: let 
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json
  plugins = [
    "ideavim"
    "nixidea"
    "github-copilot"
  ];
  patched-idea = with pkgs; (jetbrains.plugins.addPlugins jetbrains.idea-ultimate plugins);
  # Override LD_LIBREARY_PATH for minecraft mod dev(requires udev and libGL)
  # See: LD libraries (os/core/shared/ld.nix)
  # Script Reference: https://github.com/Mic92/nix-ld?tab=readme-ov-file#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld
  idea = (pkgs.writeShellScriptBin "idea-ultimate" ''
  export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
  exec ${patched-idea}/bin/idea-ultimate "$@"
  '');
  ides = with pkgs.jetbrains; [
    webstorm
    rust-rover
  ];
in  {
  home.packages = with pkgs; [
    android-studio
    # basically should not use toolbox because of issues(https://github.com/NixOS/nixpkgs/issues/240444) but useful to preview IDE 
    jetbrains-toolbox
  ] 
  ++ (map (ide: (jetbrains.plugins.addPlugins ide plugins)) ides) 
  ++ [idea];
}