{ pkgs, ... }: {
  home.packages = with pkgs; [
    discord
    discord-ptb
    vesktop
    slack
  ];
  # Skip update check
  home.file.".config/discord/settings.json".text = ''
    {
      "SKIP_HOST_UPDATE": true
    }
  '';
}
