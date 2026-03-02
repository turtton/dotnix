self: prev: {
  android-studio = prev.android-studio.override {
    buildFHSEnv = args: prev.buildFHSEnv (args // { dieWithParent = false; });
  };
}
