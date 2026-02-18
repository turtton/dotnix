{ pkgs, ... }:
{
  # boot.kernelModules = [ "amdgpu" ];
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };
    amdgpu = {
      overdrive.enable = true;
      opencl.enable = true;
    };
  };
  services.lact.enable = true;
  services.ollama = {
    enable = true;
    rocmOverrideGfx = "11.0.0";
  };
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
  nixpkgs.config.rocmSupport = true;
}
