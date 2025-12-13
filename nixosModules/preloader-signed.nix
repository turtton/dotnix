# NixOS module for PreLoader UEFI Secure Boot
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.boot.loader.systemd-boot.preloader-signed;
  packages = import ../packages/preloader-signed.nix { inherit pkgs; };
in
{
  options.boot.loader.systemd-boot.preloader-signed = {
    enable = lib.mkEnableOption "PreLoader for UEFI Secure Boot";

    efiSystemDrive = lib.mkOption {
      type = lib.types.str;
      example = "nvme0n1";
      description = "EFI system drive device name (without /dev/ prefix)";
    };

    efiPartId = lib.mkOption {
      type = lib.types.str;
      example = "1";
      description = "EFI partition ID number";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.efibootmgr ];

    boot.loader.systemd-boot.extraFiles = {
      "EFI/systemd/PreLoader.efi" = "${packages.preLoader}/share/${packages.preLoader.pname}.efi";
      "EFI/systemd/HashTool.efi" = "${packages.hashTool}/share/${packages.hashTool.pname}.efi";
      # loader.efi is a copy of systemd-bootx64.efi for PreLoader
      "EFI/systemd/loader.efi" = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-bootx64.efi";
      # Fallback settings
      "EFI/BOOT/HashTool.efi" = "${packages.hashTool}/share/${packages.hashTool.pname}.efi";
      "EFI/BOOT/BOOTx64.EFI" = "${packages.preLoader}/share/${packages.preLoader.pname}.efi";
      "EFI/BOOT/loader.efi" = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-bootx64.efi";
    };

    system.activationScripts.bootentry.text = ''
      ${pkgs.efibootmgr}/bin/efibootmgr --unicode --disk /dev/${cfg.efiSystemDrive} --part ${cfg.efiPartId} --create --label "PreLoader" --loader /boot/EFI/systemd/PreLoader.efi
    '';
  };
}
