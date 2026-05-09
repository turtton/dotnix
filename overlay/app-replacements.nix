inputs: self: prev: {
  siketyan-ghr = inputs.siketyan-ghr.packages."${self.stdenv.hostPlatform.system}".default;
  mixxx = inputs.mixxx.packages."${prev.stdenv.hostPlatform.system}".default;
}
