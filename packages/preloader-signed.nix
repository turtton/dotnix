# PreLoader and HashTool packages for UEFI Secure Boot
# Original: https://aur.archlinux.org/packages/preloader-signed
# Wiki:
# - https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#PreLoader
# - https://wiki.archlinux.jp/index.php/Unified_Extensible_Firmware_Interface/%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%83%96%E3%83%BC%E3%83%88#PreLoader
{ pkgs }:
let
  mkTool =
    name: hash:
    pkgs.stdenv.mkDerivation rec {
      pname = name;
      version = "20130208-1";
      src = pkgs.fetchurl {
        name = name;
        url = "https://web.archive.org/blog.hansenpartnership.com/wp-uploads/2013/${name}.efi";
        inherit hash;
      };
      sourceRoot = ".";
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/share
        cp $src ${name}.efi
        install -D -m0644 -t $out/share/ ${name}.efi
      '';
    };
in
{
  preLoader = mkTool "PreLoader" "sha256-UJBhFMWj+TwQECgp0Fcgbjwyvt/0rtP4mldt4cnp5ao=";
  hashTool = mkTool "HashTool" "sha256-kZ81Ye6lyyBoHZCYaxzte2J66tCUlhlDJfaBx8zBRGg=";
}
