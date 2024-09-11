{ pkgs, ... }:
let
  ghr = with pkgs; rustPlatform.buildRustPackage rec {
    pname = "ghr";
    version = "0.4.4";
    src = fetchFromGitHub {
      owner = "siketyan";
      repo = "ghr";
      rev = "v${version}";
      hash = "sha256-L9+rcdt+MGZSCOJyCE4t/TT6Fjtxvfr9LBJYyRrx208=";
    };

    cargoHash = "sha256-HBVMDR+3UB+zWmvZXBph36bajTOAnvVGTGYooJtk9Zg=";

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ openssl ];

    meta = with lib; {
      description = "Yet another repository management with auto-attaching profiles.";
      homepage = "https://github.com/siketyan/ghr";
      license = with licenses; [ mit ];
    };
  };
in
{
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
