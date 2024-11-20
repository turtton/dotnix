{ pkgs, lib, inputs, ... }:
let
  nvim-project = inputs.turtton-neovim.packages.${pkgs.system};
in
{
  home = {
    packages = [ nvim-project.default pkgs.neovide ];
    sessionVariables.EDITOR = "nvim";
    file.".config/nvim" = {
      source = nvim-project.config;
      recursive = true;
    };
  };
  xdg.mimeApps.defaultApplications = {
    "text/plain" = [ "${pkgs.neovide}/share/applications/neovide.desktop" ];
  };
}
