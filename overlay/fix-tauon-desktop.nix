final: prev: {
  tauon = prev.symlinkJoin {
    inherit (prev.tauon)
      pname
      version
      meta
      passthru
      ;
    name = "${prev.tauon.name}-desktop-fixed";
    paths = [ prev.tauon ];
    postBuild = ''
      rm "$out/share/applications/tauonmb.desktop"
      substitute ${prev.tauon}/share/applications/tauonmb.desktop \
        "$out/share/applications/tauonmb.desktop" \
        --replace-fail 'Exec=tauonmb %U' 'Exec=tauon %U'
    '';
  };
}
