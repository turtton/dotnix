# See also os/desktop/shared/bitwarden.nix
{ pkgs, hostPlatform, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "fun.dust0146@turtton.net";
      pinentry = if hostPlatform.isLinux then pkgs.pinentry-qt else pkgs.pinentry_mac;
    };
  };
  home.packages =
    with pkgs;
    lib.optionals hostPlatform.isLinux [
      bitwarden-cli
      bitwarden-desktop
      # keyguard
    ];
}
