{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "mtgto/macskk"
      "BarutSRB/tap"
      "steipete/tap"
      "fuwasegu/tap"
    ];
    casks = [
      "macskk"
      "barutsrb/tap/omniwm"
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
