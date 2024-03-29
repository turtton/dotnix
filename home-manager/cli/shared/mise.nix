{ lib, ... }: {
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
  home.activation = {
    linkMiseDirToAsdf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ASDF=$HOME/.asdf
      if [ ! -d "$ASDF" ]; then
        ln -s $VERBOSE_ARG $HOME/.local/share/mise $ASDF
      fi
    '';
  };
}
