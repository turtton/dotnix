self: prev: {
  buildFHSEnv =
    args:
    if builtins.isFunction args then
      prev.buildFHSEnv (
        final:
        let
          a = args final;
        in
        a // { dieWithParent = a.dieWithParent or false; }
      )
    else
      prev.buildFHSEnv (args // { dieWithParent = args.dieWithParent or false; });
}
