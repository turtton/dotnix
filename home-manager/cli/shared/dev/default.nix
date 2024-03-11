{pkgs, ...}: {
  home.packages = with pkgs; [
    gcc
    go
    nodejs-slim
    nodePackages.wrangler
    deno
    bun
    python312
  ];
}