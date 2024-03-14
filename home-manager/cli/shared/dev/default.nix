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
    # python312 conflicts on os/wm/plasma5.nix#environment.systemPackages.python3Full
    jdk21

    ktlint
  ];
}