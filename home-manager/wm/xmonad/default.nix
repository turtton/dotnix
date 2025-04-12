{
  xsession.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    config = ./xmonad.hs;
    libFiles = builtins.foldl' (acc: name: acc // { "${name}" = ./Custom + "/${name}"; }) { } (
      builtins.attrNames (builtins.readDir ./Custom)
    );
  };
}
