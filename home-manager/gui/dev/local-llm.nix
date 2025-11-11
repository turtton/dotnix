{ pkgs, hostPlatform, ... }:
{
  home.packages =
    with pkgs;
    lib.optionals hostPlatform.isLinux [
      jan
      # broken on darwin
      lmstudio
    ];
}
