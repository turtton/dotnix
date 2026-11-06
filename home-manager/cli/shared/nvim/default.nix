{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  nvim-project = inputs.turtton-neovim.packages.${pkgs.stdenv.system};
in
{
  home = {
    packages = [
      nvim-project.default
    ]
    ++ lib.optional (!pkgs.stdenv.hostPlatform.isDarwin) pkgs.neovide;
    sessionVariables.EDITOR = "nvim";
    file.".config/nvim" = {
      source = nvim-project.config;
      recursive = true;
    };
  };
  xdg.mimeApps.defaultApplications = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    "text/plain" = [ "${pkgs.neovide}/share/applications/neovide.desktop" ];
  };
}
