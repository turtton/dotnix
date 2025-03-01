{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = (with pkgs.vscode-extensions; [
        mkhl.direnv
        oderwat.indent-rainbow
        wakatime.vscode-wakatime
        # AI
        github.copilot-chat
        github.copilot
        saoudrizwan.claude-dev
        ## Languages
        ms-azuretools.vscode-docker
        redhat.vscode-yaml
        # python
        ms-python.python
        ms-python.vscode-pylance
        ms-toolsai.jupyter
        ms-toolsai.vscode-jupyter-slideshow
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-cell-tags
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
      ]);
      userSettings = {
        "workbench.productIconTheme" = "a-file-icon-vscode-product-icon-theme";
        "workbench.colorTheme" = "50 Shades of Purple";
        "files.autoSave" = "off";
      };
    };
  };
  home.packages = with pkgs; [
    # nixd
    nil
    code-cursor
  ];
}
