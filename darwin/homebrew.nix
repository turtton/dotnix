{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "mtgto/macskk"
      "steipete/tap"
      "fuwasegu/tap"
    ];
    casks = [
      "macskk"
      "codexbar"
      "background-music"
      "scroll-reverser"
      "fuwasegu/tap/airlingua"
      "deskpad"
    ];
    brews = [
      "can1357/tap/omp"
    ];
  };
}
