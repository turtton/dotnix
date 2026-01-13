{
  userName,
  userEmail,
  signingKey ? "",
}:
{ pkgs, ... }:
{
  programs = {
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
      };
    };
    git = {
      enable = true;
      lfs.enable = true;
      signing = {
        key = signingKey;
        signByDefault = true;
      };
      # Some ocnfigurations reffered from https://blog.gitbutler.com/how-git-core-devs-configure-git/
      settings = {
        user = {
          name = userName;
          email = userEmail;
        };
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
        aliases = {
          log-graph = "log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset' --abbrev-commit --date=format-local:'%Y/%m/%d %H:%M:%S'";
        };
        url = {
          "git@github.com:".insteadOf = "https://github.com/";
        };
      };
      ignores = [
        ".idea"
        ".vscode"
        "*.local.md"
        "*.local.json"
        ".gemini"
        ".claude"
      ];
    };
    gh = {
      enable = true;
      extensions = with pkgs; [ gh-markdown-preview ];
      settings = {
        editor = "nvim";
      };
    };
    lazygit = {
      enable = true;
      settings = {
        git = {
          overrideGpg = true;
          autoForwardBranches = "none";
        };
        gui = {
          showIcons = true;
          nerdFontsVersion = "3";
        };
        customCommands = [
          # localBranches: 選択したローカルブランチを指定ディレクトリに worktree 追加
          {
            key = "w";
            command = "git worktree add ../{{.Form.Path}} {{.SelectedLocalBranch.Name}}";
            description = "Add worktree for selected branch";
            context = "localBranches";
            prompts = [
              {
                type = "input";
                title = "New worktree path (directory name)";
                key = "Path";
                suggestion = ''{{.SelectedLocalBranch.Name | replace "/" "-"}}'';
              }
            ];
          }
          # remoteBranches: 選択したリモートブランチをローカル化してから worktree 追加
          {
            key = "w";
            command = "bash -lc 'set -e; BR={{.SelectedRemoteBranch.Name}}; DIR=../{{.Form.Path}}; if git show-ref --verify --quiet refs/heads/$BR; then git worktree add \"$DIR\" \"$BR\"; else git fetch --prune; git worktree add -b \"$BR\" \"$DIR\" origin/$BR; fi; git -C \"$DIR\" branch --set-upstream-to=origin/$BR \"$BR\" || true'";
            description = "Add worktree for selected remote branch (auto create/use local and set upstream)";
            context = "remoteBranches";
            prompts = [
              {
                type = "input";
                title = "New worktree path (directory name)";
                key = "Path";
                suggestion = ''{{.SelectedRemoteBranch.Name | replace "/" "-"}}'';
              }
            ];
          }
          # worktrees: BaseBranch から NewBranch を作成し、指定ディレクトリに worktree 追加
          {
            key = "W";
            command = "git worktree add -b {{.Form.NewBranch}} ../{{.Form.Path}} {{.Form.BaseBranch}}";
            description = "Create new branch as worktree";
            context = "worktrees";
            prompts = [
              {
                type = "input";
                title = "New worktree path (directory name)";
                key = "Path";
                suggestion = "{{.Form.NewBranch}}";
              }
              {
                type = "input";
                title = "New branch name";
                key = "NewBranch";
              }
              {
                type = "input";
                title = "Base branch to create from (e.g., main or master)";
                key = "BaseBranch";
                initialValue = "main";
              }
            ];
          }
        ];
      };
    };
  };
  home.packages = with pkgs; [
    gitmoji-cli
  ];
}
