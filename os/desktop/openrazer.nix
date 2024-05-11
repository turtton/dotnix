{ usernames, pkgs, ... }: {
  hardware.openrazer = {
    enable = true;
    users = usernames;
  };
  environment.systemPackages = with pkgs; [
    polychromatic
  ];
}
