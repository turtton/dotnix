{
  imports = [
    ../common
  ];

  # Limit the number of boot loader configurations
  boot.loader = {
    grub.configurationLimit = 5;
    generic-extlinux-compatible.configurationLimit = 5;
  };
}
