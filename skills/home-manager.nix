{ dotagents }:
{ config, ... }:
{
  programs.agent-skills = {
    enable = true;
    sources = {
      dotagents = {
        path = dotagents;
        subdir = "skills";
      };
    };
    skills.enableAll = true;
    targets.opencode = {
      enable = true;
      dest = "${config.xdg.configHome}/opencode/skill";
      structure = "copy-tree";
    };
    targets.senpi = {
      enable = true;
      dest = "${config.home.homeDirectory}/.senpi/agent/skills";
      structure = "copy-tree";
    };
  };
}
