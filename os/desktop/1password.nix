{ pkgs, usernames, ... }:
{
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = usernames;
    };
  };
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
                vivaldi-bin
        				.zen-wrapped
      '';
      mode = "0755";
    };
  };
}
