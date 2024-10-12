{ pkgs, lib, inputs, ... }:
let
  nvim-project = inputs.turtton-neovim.packages.${pkgs.system};
in
{
  programs.neovim = {
    vimAlias = true;
    defaultEditor = true;
  };
  home.packages = [
    nvim-project.default
  ];
  home.file.".config/nvim" = {
    source = nvim-project.config;
    recursive = true;
  };
}
