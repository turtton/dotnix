{ lib, ... }: {
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
  home.activation = {
    linkMiseDirToAsdf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ln -s $VERBOSE_ARG $HOME/.local/share/mise $HOME/.asdf
    '';
  };
}
