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

    efiPartUuid = lib.mkOption {
      type = lib.types.str;
      example = "EB99-92A5";
      description = "UUID of the EFI system partition (FAT32). Used to dynamically resolve the disk device, making the config resilient to NVMe enumeration order changes across reboots.";
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
      # Resolve disk and partition number from ESP UUID, resilient to NVMe enumeration changes
      ESP_DEV=$(readlink -f /dev/disk/by-uuid/${cfg.efiPartUuid})
      # Extract partition number (e.g. /dev/nvme1n1p1 -> 1)
      PART_NUM=$(echo "$ESP_DEV" | grep -oP '\d+$')
      # Strip partition suffix to get disk (e.g. /dev/nvme1n1p1 -> /dev/nvme1n1)
      DISK_DEV=$(echo "$ESP_DEV" | sed 's/p[0-9]*$//')
      ${pkgs.efibootmgr}/bin/efibootmgr --unicode --disk "$DISK_DEV" --part "$PART_NUM" --create --label "PreLoader" --loader /boot/EFI/systemd/PreLoader.efi
    '';
  };
}
