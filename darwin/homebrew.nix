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
      "omniwm"
      "codexbar"
      "background-music"
      "scroll-reverser"
      "airlingua"
      "deskpad"
    ];
    # https://github.com/nix-darwin/nix-darwin/issues/1787
    onActivation.extraFlags = [
      "--force-cleanup"
    ];
  };
}
