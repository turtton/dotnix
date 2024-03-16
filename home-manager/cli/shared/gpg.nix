{ pkgs, ... }:{
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };
  services.gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
  };
}