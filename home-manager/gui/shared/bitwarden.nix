{ pkgs, hostPlatform, ... }: {
  programs.rbw = {
    enable = true;
    email = "fun.dust0146@turtton.net";
  };
  home.packages = with pkgs; lib.options hostPlatform.isLinux [
    bitwarden-desktop
  ];
}
