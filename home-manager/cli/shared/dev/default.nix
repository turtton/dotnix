{ pkgs, ... }: {
  imports = [
    ./cargo.nix
    ./ghr.nix
  ];
  home.packages = with pkgs; [
    gcc
    go
    nodejs_21
    nodePackages.wrangler
    deno
    bun
    # python312 conflicts on os/wm/plasma5.nix#environment.systemPackages.python3Full
    jdk21

    ktlint
  ];
}
