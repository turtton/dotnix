{ inputs, system, ... }:
{
  imports = [
    inputs.hyprland.nixosModules.default
    inputs.noctalia.nixosModules.default
  ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };
  # programs.hyprlock.enable = true;
  security.pam.services =
    let
      enableKeyrings = {
        enableGnomeKeyring = true;
        kwallet.enable = true;
      };
    in
    {
      login = enableKeyrings;
      hyprlock = enableKeyrings;
    };
  # Used by hyprpanel
  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    noctalia-shell.enable = true;
  };
}
