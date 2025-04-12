term:
{ pkgs, ... }:
{
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = term;
  };

  environment = {
    sessionVariables = {
      NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
      NAUTILUS_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-3.0";
    };
    pathsToLink = [
      "/share/nautilus-python/extensions"
    ];

    systemPackages = with pkgs; [
      nautilus
      nautilus-python
      jetbrains-nautilus
      sushi
      turtle
    ];
  };
}
