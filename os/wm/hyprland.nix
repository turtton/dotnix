{ inputs, ... }: {
  imports = [ inputs.hyprland.nixosModules.default ];
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;
}
