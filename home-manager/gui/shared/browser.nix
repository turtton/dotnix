{ system, inputs, ... }: {
  programs = {
    firefox.enable = true;
    chromium.enable = true;
    vivaldi = {
      enable = true;
    };
  };
  home.packages = [
    inputs.zen-browser.packages."${system}".default
  ];
}
