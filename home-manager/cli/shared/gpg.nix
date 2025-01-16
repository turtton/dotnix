{ pkgs, ... }: {
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };
  services.gpg-agent = {
    enable = true;
    pinentryPackage = if pkgs.hostPlatform.isLinux then pkgs.pinentry-all else pkgs.pinentry_mac;
  };
}
