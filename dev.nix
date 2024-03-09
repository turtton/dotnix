{pkgs, ...}: {
  home.packages = with pkgs; [
    # Language Compiler and Runtimes
    gcc
    go
    nodejs-slim
    nodePackages.wrangler
    deno
    bun
    python312
    rust-bin.stable.latest.default
    # Editors
    vscode
  ];
}