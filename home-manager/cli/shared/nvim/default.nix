{ pkgs, lib, inputs, ... }:
let
  nvim-project = inputs.turtton-neovim.packages.${pkgs.system};
in
{
  programs.neovim = {
    vimAlias = true;
    defaultEditor = true;
    package = nvim-project;
  };
  home.file.".config/nvim" = {
    source = nvim-project.config;
    recursive = true;
  };
}
