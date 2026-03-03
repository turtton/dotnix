self: prev: {
  buildFHSEnv = args: prev.buildFHSEnv (args // { dieWithParent = args.dieWithParent or false; });
}
