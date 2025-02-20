gen: self: prev:
# https://github.com/NixOS/nixpkgs/issues/383059
let
  rust-toolchain = gen.src + "/rustowl/rust-toolchain.toml";
  toolchain = self.rust-bin.fromRustupToolchainFile rust-toolchain;
  nightlyRustPlatform = self.makeRustPlatform { cargo = toolchain; rustc = toolchain; };
in
{
  rustowl = with self; nightlyRustPlatform.buildRustPackage rec {
    inherit (gen) version;
    pname = "cargo-owl";
    name = gen.pname;

    src = gen.src + "/rustowl";

    cargoLock.lockFile = "${src}/Cargo.lock";
    useFetchCargoVendor = true;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ curl ];

    meta = with lib; {
      description = "A Rust library for parsing and manipulating OWL files.";
      homepage = "https://github.com/cordx56/rustowl";
      license = with licenses; [ mit ];
    };
  };
}
