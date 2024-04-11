{ inputs, system, pkgs, ... }:
let
  extension = inputs.nix-vscode-extensions.extensions."${system}";
in
{
  programs.vscode = {
    enable = true;
    extensions = with extension; [
      vscode-marketplace.re7rix2."50-shades-of-purple"
      vscode-marketplace.atommaterial.a-file-icon-vscode
      vscode-marketplace.me-dutour-mathieu.vscode-github-actions
      vscode-marketplace.github.copilot-chat
      vscode-marketplace.github.copilot
      open-vsx.pinage404.nix-extension-pack
      vscode-marketplace.mkhl.direnv
      vscode-marketplace."42crunch".vscode-openapi
      # https://github.com/nix-community/nix-vscode-extensions/issues/31
      (vscode-marketplace.typespec.typespec-vscode.overrideAttrs (_: { sourceRoot = "extension"; }))
      open-vsx.asvetliakov.vscode-neovim
      vscode-marketplace.wakatime.vscode-wakatime
      open-vsx.redhat.vscode-yaml
      vscode-marketplace.ms-python.python
      vscode-marketplace.ms-python.vscode-pylance
      vscode-marketplace.njpwerner.autodocstring
      vscode-marketplace.oderwat.indent-rainbow
      vscode-marketplace.ms-toolsai.jupyter
      vscode-marketplace.ms-toolsai.vscode-jupyter-slideshow
      vscode-marketplace.ms-toolsai.jupyter-keymap
      vscode-marketplace.ms-toolsai.jupyter-renderers
      vscode-marketplace.ms-toolsai.vscode-jupyter-cell-tags
    ];
    userSettings = {
      "workbench.productIconTheme" = "a-file-icon-vscode-product-icon-theme";
      "workbench.colorTheme" = "50 Shades of Purple";
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "files.autoSave" = "off";
    };
  };
  home.packages = with pkgs; [
    # nixd
    nil
  ];
}
