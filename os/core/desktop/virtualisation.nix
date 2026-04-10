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
    winboat
  ];
}
