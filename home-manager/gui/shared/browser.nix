{
  system,
  inputs,
  pkgs,
  ...
}:
let
  isLinux = pkgs.hostPlatform.isLinux;
in
{
  programs = {
    firefox = {
      enable = isLinux;
      package = if isLinux then pkgs.firefox else pkgs.firefox-unwrapped;
    };
    chromium.enable = isLinux;
    vivaldi.enable = isLinux;
  };
  home.packages = pkgs.lib.optionals isLinux [
    inputs.zen-browser.packages."${system}".default
  ];
}
