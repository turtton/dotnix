{ pkgs, hostPlatform, ... }:
{
  home.packages =
    with pkgs;
    [
      obsidian
      typora
    ]
    ++ lib.optionals hostPlatform.isLinux [
      evince
      libreoffice
    ];
}
