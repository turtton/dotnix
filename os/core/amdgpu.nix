{ pkgs, ... }:
{
  boot.kernelModules = [ "amdgpu" ];
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        amdvlk
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
    amdgpu = {
      overdrive.enable = true;
      opencl.enable = true;
    };
  };
  services.lact.enable = true;
  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
        ];
      };
    in
    [
      "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
    ];
  environment.systemPackages = with pkgs; [
    clinfo
  ];

}
