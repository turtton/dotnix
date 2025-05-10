{ pkgs, hostPlatform, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };
  services.gpg-agent = {
    enable = true;
    pinentry.package = if hostPlatform.isLinux then pkgs.pinentry-qt else pkgs.pinentry_mac;
  };
}
