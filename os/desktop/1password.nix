{pkgs, ...}:
{
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "turtton" ];
    };
    ssh.extraConfig = ''
      Host *
        IdentitiesOnly=yes
        IdentityAgent ~/.1password/agent.sock
    '';
  };
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        vivaldi-bin
      '';
      mode = "0755";
    };
  };
}