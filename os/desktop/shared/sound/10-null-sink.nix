#https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Virtual-Devices#coupled-streams
{
  "context.modules" = [
    {
      name = "libpipewire-module-loopback";
      args = {
        "audio.position" = [ "FL" "FR" ];
        "capture.props" = {
          "media.class" = "Audio/Sink";
          "node.name" = "obs_sink";
          "node.description" = "obs-sink";
          #node.latency = 1024/48000;
          #audio.rate = 44100;
          #audio.channels = 2;
          #audio.position = [ FL FR ];
          #target.object = "obs-default-sink";
        };
        "playback.props" = {
          #media.class = Audio/Source;
          "node.name" = "obs_source";
          "node.description" = "obs-source";
          #node.latency = 1024/48000;
          #audio.rate = 44100;
          #audio.channels = 2;
          #audio.position = [ FL FR ];
          "target.object" = "obs-default-source";
        };
      };
    }
  ];
}
