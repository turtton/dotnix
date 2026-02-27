{ pkgs, ... }:
{
  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    extraConfig.pipewire = {
      "10-null-sink" = (import ./10-null-sink.nix);
      "10-clock-rate" = {
        "context.properties" = {
          "default.clock.rate" = 44100;
          "default.clock.allowed-rates" = [
            44100
            48000
            96000
          ];
          "resample.quality" = 10;
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    qpwgraph
  ];
}
