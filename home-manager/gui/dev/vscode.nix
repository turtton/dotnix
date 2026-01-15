{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions =
        (
          with pkgs.vscode-extensions;
          [
            arrterian.nix-env-selector
            jnoortheen.nix-ide
            mkhl.direnv
            oderwat.indent-rainbow
            wakatime.vscode-wakatime
            ms-vscode-remote.remote-containers
            marp-team.marp-vscode
            ms-kubernetes-tools.vscode-kubernetes-tools
            github.vscode-github-actions
            antfu.slidev
            # AI
            github.copilot-chat
            github.copilot
            # Languages
            ms-azuretools.vscode-docker
            redhat.vscode-yaml
            yoavbls.pretty-ts-errors
            james-yu.latex-workshop
            ## python
            ms-python.python
            ms-python.vscode-pylance
            charliermarsh.ruff
            ms-toolsai.jupyter
            ms-toolsai.vscode-jupyter-slideshow
            ms-toolsai.jupyter-keymap
            ms-toolsai.jupyter-renderers
            ms-toolsai.vscode-jupyter-cell-tags
            ### Javascript/TypeScript
            esbenp.prettier-vscode
            dbaeumer.vscode-eslint
            ### Svelte
            svelte.svelte-vscode
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            saoudrizwan.claude-dev
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            rooveterinaryinc.roo-cline
          ]
        )
        ++ (with pkgs; [
          vscode-marketplace.re7rix2."50-shades-of-purple"
          vscode-marketplace.atommaterial.a-file-icon-vscode
          vscode-marketplace.me-dutour-mathieu.vscode-github-actions
          vscode-marketplace."42crunch".vscode-openapi
          vscode-marketplace.typespec.typespec-vscode
          vscode-marketplace.njpwerner.autodocstring
          vscode-marketplace.matt-meyers.vscode-dbml
          vscode-marketplace.bocovo.dbml-erd-visualizer
          vscode-marketplace.ardenivanov.svelte-intellisense
          vscode-marketplace.fivethree.vscode-svelte-snippets
          vscode-marketplace.aidan-gibson.river
        ]);
      userSettings = {
        "workbench.productIconTheme" = "a-file-icon-vscode-product-icon-theme";
        "workbench.colorTheme" = "50 Shades of Purple";
        "files.autoSave" = "off";
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
        "svelte.enable-ts-plugin" = true;
        "roo-cline.allowedCommands" = [
          "cargo clippy"
          "tsc"
          "git log"
          "git diff"
          "git show"
        ];
        "claudeCode.preferredLocation" = "panel";
        "claudeCode.useTerminal" = true;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        "cline.chromeExecutablePath" = pkgs.lib.makeBinPath [ pkgs.chromium ] + "/" + pkgs.chromium.pname;
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
