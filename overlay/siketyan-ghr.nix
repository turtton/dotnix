inputs: self: prev: {
  siketyan-ghr = inputs.siketyan-ghr.packages."${self.stdenv.hostPlatform.system}".default;
}
