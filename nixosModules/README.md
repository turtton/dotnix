# NixOS Modules

Custom NixOS modules provided by this repository.

## preloader-signed

A module that integrates PreLoader and HashTool for UEFI Secure Boot with systemd-boot.

### Usage

```nix
# Add to imports
imports = [
  ./path/to/nixosModules/preloader-signed.nix
];

# Configuration
boot.loader.systemd-boot.preloader-signed = {
  enable = true;
  efiSystemDrive = "nvme0n1";  # EFI system drive
  efiPartId = "1";              # EFI partition ID
};
```

### Using from external flake

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
            efiSystemDrive = "nvme0n1";
            efiPartId = "1";
          };
        }
      ];
    };
  };
}
```

### Options

| Option | Type | Description |
|--------|------|-------------|
| `enable` | bool | Enable the module |
| `efiSystemDrive` | string | EFI system drive name (e.g., `nvme0n1`) |
| `efiPartId` | string | EFI partition number (e.g., `1`) |

### References

- [Arch Wiki - PreLoader](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#PreLoader)
- [AUR - preloader-signed](https://aur.archlinux.org/packages/preloader-signed)
