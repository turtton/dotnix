{
  pkgs,
  hostPlatform,
  config,
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
      configPath = "${config.xdg.configHome}/mozilla/firefox";
    };
    chromium.enable = isLinux;
    vivaldi.enable = isLinux;
    zen-browser.enable = true;
  };
  home.packages = pkgs.lib.optionals isLinux [
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
