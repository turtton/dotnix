{
  system,
  inputs,
  pkgs,
  hostPlatform,
  ...
}:
let
  isLinux = hostPlatform.isLinux;
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
    pkgs.google-chrome
  ];
  xdg.mimeApps.defaultApplications =
    let
      defaultBrowser = [ "vivaldi-stable.desktop" ];
    in
    {
      "x-scheme-handler/http" = defaultBrowser;
      "x-scheme-handler/https" = defaultBrowser;
      "x-scheme-handler/about" = defaultBrowser;
      "x-scheme-handler/unknown" = defaultBrowser;
    };
}
