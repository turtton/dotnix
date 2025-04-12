gen: self: prev: {
  ghr =
    with self;
    rustPlatform.buildRustPackage rec {
      inherit (gen) pname version src;

      cargoLock = {
        lockFile = "${src}/Cargo.lock";
      };

      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ openssl ];

      meta = with lib; {
        description = "Yet another repository management with auto-attaching profiles.";
        homepage = "https://github.com/siketyan/ghr";
        license = with licenses; [ mit ];
      };
    };
}
