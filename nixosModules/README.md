# NixOS Modules

Custom NixOS modules provided by this repository.

## preloader-signed

A module that integrates PreLoader and HashTool for UEFI Secure Boot with systemd-boot.

### Usage

```nix
{
  inputs.dotnix.url = "github:turtton/dotnix";

  outputs = { self, nixpkgs, dotnix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        dotnix.nixosModules.preloader-signed
        {
          boot.loader.systemd-boot.preloader-signed = {
            enable = true;
            efiPartUuid = "EB99-92A5";  # UUID of your ESP partition
          };
        }
      ];
    };
  };
}
```

### How to find your ESP UUID

`hardware-configuration.nix` の `fileSystems."/boot".device` を確認してください：

```nix
fileSystems."/boot" = {
  device = "/dev/disk/by-uuid/EB99-92A5";  # <- この値を使う
  fsType = "vfat";
};
```

または実行中のシステムで確認する場合：

```bash
blkid $(findmnt -n -o SOURCE /boot) -s UUID -o value
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `enable` | bool | Enable the module |
| `efiPartUuid` | string | UUID of the EFI system partition (e.g., `EB99-92A5`). Dynamically resolves the disk device, resilient to NVMe enumeration order changes. |

### References

- [Arch Wiki - PreLoader](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#PreLoader)
- [AUR - preloader-signed](https://aur.archlinux.org/packages/preloader-signed)
