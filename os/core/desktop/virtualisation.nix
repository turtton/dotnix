{ pkgs, ... }:
{
  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    podman = {
      enable = true;
      extraPackages = with pkgs; [
        podman-compose
      ];
    };
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
