{ pkgs, ... }: {
  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    podman.enable = true;
    libvirtd.enable = true;
  };
  environment.systemPackages = with pkgs; [
    virt-manager
  ];
}
