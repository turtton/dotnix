{ pkgs, ...}: let 
  ghr = with pkgs; rustPlatform.buildRustPackage rec {
    pname = "ghr";
    version = "0.4.2";
    src = fetchFromGitHub {
      owner = "siketyan";
      repo = "ghr";
      rev = "v${version}";
      hash = "sha256-W5zkDNge0x/oFnwnip12SfCxtZ5nAQ5c3rUAnIMZ5L0=";
    };

    cargoHash = "sha256-l9bHOrfOtNk2g6Gbt+F9uH6o0yQW5+y3KXZM98uiOiI=";

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ openssl ];

    meta = with lib; {
      description = "Yet another repository management with auto-attaching profiles.";
      homepage = "https://github.com/siketyan/ghr";
      license = with licenses; [ mit ];
    };
  };
in {
  home.packages = [
    ghr
  ];
  programs.zsh = {
    initExtra = ''
    source <(ghr shell bash)
    source <(ghr shell bash --completion)
    '';
  };
}