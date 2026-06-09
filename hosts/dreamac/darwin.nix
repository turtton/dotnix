{ pkgs, ... }:
{
  imports = [
    # ./../../darwin/jankyborders.nix
    ./../../darwin/fonts.nix
    ./../../darwin/homebrew.nix
    ./../../darwin/nix.nix
    ./../../darwin/container.nix
    ./../../darwin/skhd.nix
    ./../../darwin/yabai
    ./../../darwin/system.nix
  ];
  ids.uids.nixbld = 401;
  ids.gids.nixbld = 402;
}
