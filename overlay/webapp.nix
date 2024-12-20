self: prev: rec {
  pake-cli = with self;	rustPlatform.buildRustPackage rec {
    name = "pake";
    version = "3.0.0";
    src = fetchFromGitHub {
      owner = "tw93";
      repo = "Pake";
      rev = "V${version}";
      hash = "sha256-Rojfjt9XRnwn6+7Yf9Bpo+BJLapgRXIQUXwa7m8HAkI=";
    };
    sourceRoot = "${src.name}/src-tauri";
    cargoLock = {
      lockFile = "${src}/src-tauri/Cargo.lock";
    };
    buildInputs = [ glib gtk3 libsoup_3 webkitgtk_4_1 ];
    nativeBuildInputs = [ pkg-config makeWrapper ];

    postFixup =
      let
        binaryPath = lib.makeBinPath [ curl wget ];
        libraryPath = lib.makeLibraryPath [ libappindicator-gtk3 ];
      in
      ''
        			wrapProgram $out/bin/pake --prefix LD_LIBRARY_PATH : ${libraryPath} --prefix PATH : ${binaryPath}
        		'';

    meta = with lib; {
      description = "A powerful webapp generator";
      homepage = "https://github.com/tw93/Pake";
      license = licenses.mit;
    };
  };
  fastmail = with self; stdenv.mkDerivation {
    name = "faltmail";
    dontUnpack = true;
    buildPhase = ''
      			${pake-cli}/bin/pake https://app.fastmail.com --name fastmail --icon https://app.fastmail.com/static/favicons/icon-32x32.png --dark-mode
      			ls -la
      			cp fastmail $out/
      		'';
    meta = {
      description = "Fastmail webapp powerd by pake";
      homepage = "https://github.com/tw93/Pake";
      licenses = [ licenses.mit ];
    };
  };
}
