{ dotagents }:
{ config, lib, ... }:
{
  programs.agent-skills = {
    enable = true;
    sources = {
      dotagents = {
        path = dotagents;
        subdir = "skills";
      };
    };
    skills.explicit = lib.mapAttrs (name: skill: {
      from = skill.source;
      path = skill.relPath;
      agents = [
        "opencode"
        "senpi"
      ]
      ++ lib.optional (builtins.elem name [
        "missing-tools"
        "worktree-pr"
      ]) "agents";
    }) config.programs.agent-skills.catalog;
    targets.agents = {
      enable = true;
      dest = "${config.home.homeDirectory}/.agents/skills";
      structure = "copy-tree";
    };
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
