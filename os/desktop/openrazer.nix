{username, pkgs, ...}: {
  hardware.openrazer = {
    enable = true;
    users = [username];
  };
  environment.systemPackages = with pkgs; [
    polychromatic
  ];
}