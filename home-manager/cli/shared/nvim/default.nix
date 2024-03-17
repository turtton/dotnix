# Reference: https://github.com/natsukium/dotfiles/blob/26999a221aa48e00ab979e98e63bccac381a37fa/nix/applications/nvim/default.nix
inputs@{ pkgs, lib, ...}:
let
  configFile = file: {
    "nvim/${file}".source = ./. + "/${file}";
  };
  configFiles = files: builtins.foldl' (x: y: x // y) { } (map configFile files);
in
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    inherit (import ./plugin inputs) plugins;
    extraConfig = lib.readFile ./init.vim;
    # Add line breaking to separate extraconfig and lua configs
    extraLuaConfig = "\n";
  };
  xdg.configFile = configFiles [
    "./keybindings.vim"
    "./nvim-settings.vim"
    "./settings.vim"
  ];
}