# This nix file is for installing PreLoader and HashTool to systemd-boot.
efiSystemDrive: efiPartId: { pkgs, ...} : let 
  # Original: https://aur.archlinux.org/packages/preloader-signed
  # See: https://wiki.archlinux.jp/index.php/Unified_Extensible_Firmware_Interface/%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%83%96%E3%83%BC%E3%83%88#PreLoader
  mkTool = name: hash: with pkgs; stdenv.mkDerivation rec {
    pname = name;
    version = "20130208-1";
    src = fetchurl {
      name = name;
      url = "https://blog.hansenpartnership.com/wp-uploads/2013/${name}.efi";
      inherit hash;
    };
    sourceRoot = ".";
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out/share
      cp $src ${name}.efi
      install -D -m0644 -t $out/share/ ${name}.efi
    '';
  };
  preLoader = mkTool "PreLoader" "sha256-UJBhFMWj+TwQECgp0Fcgbjwyvt/0rtP4mldt4cnp5ao=";
  hashTool = mkTool "HashTool" "sha256-kZ81Ye6lyyBoHZCYaxzte2J66tCUlhlDJfaBx8zBRGg=";
in {
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];
  boot.loader.systemd-boot = {
    extraFiles = {
      "EFI/systemd/PreLoader.efi" = "${preLoader}/share/${preLoader.pname}.efi";
      "EFI/systemd/HashTool.efi" = "${hashTool}/share/${hashTool.pname}.efi";
      # Fallback settings
      "EFI/BOOT/HashTool.efi" = "${hashTool}/share/${hashTool.pname}.efi";
      "EFI/BOOT/BOOTx64.EFI" = "${preLoader}/share/${preLoader.pname}.efi";
    };
    extraInstallCommands = ''
      # I dont know why, but this shell cannnot use cat command.
      ${pkgs.uutils-coreutils-noprefix}/bin/cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi
      # Fallback settings
      ${pkgs.uutils-coreutils-noprefix}/bin/cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/loader.efi
      # ${pkgs.uutils-coreutils-noprefix}/bin/cp ${preLoader}/share/${preLoader.pname}.efi /boot/EFI/BOOT/BOOTX64.EFI
    '';
  };
  system.activationScripts = {
    bootentry.text = ''
      ${pkgs.efibootmgr}/bin/efibootmgr --unicode --disk /dev/${efiSystemDrive} --part ${efiPartId} --create --label "PreLoader" --loader /boot/EFI/systemd/PreLoader.efi
    '';
  };
}