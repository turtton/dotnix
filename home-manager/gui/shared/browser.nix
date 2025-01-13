{ system, inputs, pkgs, ... }:
let
  isLinux = pkgs.hostPlatform.isLinux;
in
{
  programs = {
    firefox.enable = true;
    chromium.enable = true;
    vivaldi.enable = isLinux;
  };
  home.packages = pkgs.lib.optionals isLinux [
    inputs.zen-browser.packages."${system}".default
  ];
}
