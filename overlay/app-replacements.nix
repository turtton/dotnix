inputs: self: prev: {
  # Upstream's rust-toolchain.toml uses the default profile, which pulls rust-docs into the build.
  siketyan-ghr = inputs.siketyan-ghr.packages."${self.stdenv.hostPlatform.system}".default.override {
    rust-bin = self.rust-bin // {
      fromRustupToolchainFile =
        file:
        self.rust-bin.fromRustupToolchain (
          (builtins.fromTOML (builtins.readFile file)).toolchain // { profile = "minimal"; }
        );
    };
  };
}
