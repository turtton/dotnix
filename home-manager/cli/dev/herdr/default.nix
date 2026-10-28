{ pkgs, ... }:
{
  home.packages = [
    pkgs.llm-agents.herdr
  ];
  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
