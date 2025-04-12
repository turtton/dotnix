{ lib, ... }:
{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
  home.activation = {
    linkMiseDirToAsdf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ASDF=$HOME/.asdf
      ln -fs $VERBOSE_ARG $HOME/.local/share/mise $ASDF
    '';
  };
}
