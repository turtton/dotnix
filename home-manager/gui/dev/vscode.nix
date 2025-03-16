{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        mkhl.direnv
        oderwat.indent-rainbow
        wakatime.vscode-wakatime
        ms-vscode-remote.remote-containers
        # AI
        github.copilot-chat
        github.copilot
        # Languages
        ms-azuretools.vscode-docker
        redhat.vscode-yaml
        yoavbls.pretty-ts-errors
        ## python
        ms-python.python
        ms-python.vscode-pylance
        charliermarsh.ruff
        ms-toolsai.jupyter
        ms-toolsai.vscode-jupyter-slideshow
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-cell-tags
        ### Svelte
        svelte.svelte-vscode
      ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        saoudrizwan.claude-dev
      ]) ++ (with pkgs; [
        vscode-marketplace.re7rix2."50-shades-of-purple"
        vscode-marketplace.atommaterial.a-file-icon-vscode
        vscode-marketplace.me-dutour-mathieu.vscode-github-actions
        open-vsx.pinage404.nix-extension-pack
        vscode-marketplace."42crunch".vscode-openapi
        vscode-marketplace.typespec.typespec-vscode
        vscode-marketplace.njpwerner.autodocstring
        vscode-marketplace.matt-meyers.vscode-dbml
        vscode-marketplace.bocovo.dbml-erd-visualizer
        vscode-marketplace.ardenivanov.svelte-intellisense
        vscode-marketplace.fivethree.vscode-svelte-snippets
        vscode-marketplace.aidan-gibson.river
      ] ++ lib.optionals stdenv.isLinux [
        vscode-marketplace.rooveterinaryinc.roo-cline
      ]);
      userSettings = {
        "workbench.productIconTheme" = "a-file-icon-vscode-product-icon-theme";
        "workbench.colorTheme" = "50 Shades of Purple";
        "files.autoSave" = "off";
        "cline.chromeExecutablePath" = pkgs.lib.makeBinPath [ pkgs.chromium ] + "/" + pkgs.chromium.pname;
        "notebook.formatOnSave.enabled" = true;
        "notebook.codeActionsOnSave" = {
          "notebook.source.fixAll" = "explicit";
          "notebook.source.organizeImports" = "explicit";
        };
        "[python]" = {
          "editor.formatOnSave" = true;
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
            "source.organizeImports" = "explicit";
          };
        };
        "roo-cline.allowedCommands" = [
          "cargo clippy"
          "tsc"
          "git log"
          "git diff"
          "git show"
        ];
      };
    };
  };
  home.file.".vscode/argv.json".text = builtins.toJSON {
    enable-crash-reporter = false;
    password-store = "gnome-libsecret";
  };
  home.packages = with pkgs; [
    # nixd
    nil
  ];
}
