{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
  };
  environment.systemPackages = with pkgs; [
    virt-manager
    # https://github.com/NixOS/nixpkgs/issues/537847
    # winboat
  ];
}
