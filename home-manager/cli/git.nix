{ userName, userEmail, signingKey ? "", }:
{ pkgs, ... }: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    inherit userName userEmail;
    signing = {
      key = signingKey;
      signByDefault = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
      };
    };
    # Some ocnfigurations reffered from https://blog.gitbutler.com/how-git-core-devs-configure-git/
    extraConfig = {
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      init.defaultBranch = "main";
      core = {
        autocrlf = "input";
        editor = "nvim";
      };
      pack = {
        windowMemory = "2g";
        packSizeLimit = "1g";
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      help.autocorrect = "prompt";
      commit.verbose = true;
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
    };
    ignores = [ ".idea" ".vscode" ".memo.local.md" ];
  };
  programs.gh = {
    enable = true;
    extensions = with pkgs; [ gh-markdown-preview ];
    settings = {
      editor = "nvim";
    };
  };
  home.packages = with pkgs; [
    lazygit
    gitmoji-cli
  ];
}
