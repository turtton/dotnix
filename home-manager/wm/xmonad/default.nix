{
  xsession.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    config = ./xmonad.hs;
    libFiles = builtins.attrNames (builtins.readDir ./Custom);
  };
}
