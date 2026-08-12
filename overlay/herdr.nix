# Upstream's overlays.default re-applies rust-overlay; alias its package output directly.
inputs: self: prev: {
  herdr = inputs.herdr.packages."${self.stdenv.hostPlatform.system}".default;
}
