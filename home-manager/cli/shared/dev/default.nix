{pkgs, ...}: {
  imports = [
    ./cargo.nix
  ];
  home.packages = with pkgs; [
    gcc
    go
    nodejs-slim
    nodePackages.wrangler
    deno
    bun
    python312
    jdk21

    ktlint
  ];
}