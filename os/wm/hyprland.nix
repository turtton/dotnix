{ inputs, system, ... }: {
  imports = [ inputs.hyprland.nixosModules.default ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };
  programs.hyprlock.enable = true;
}
