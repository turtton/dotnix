_final: prev: {
  tauon = prev.tauon.overrideAttrs (oldAttrs: {
    # https://github.com/NixOS/nixpkgs/issues/577587
    preFixup = (oldAttrs.preFixup or "") + ''
      for i in "''${!makeWrapperArgs[@]}"; do
        case "''${makeWrapperArgs[$i]}" in
          '$GI_TYPELIB_PATH')
            makeWrapperArgs[$i]="$GI_TYPELIB_PATH"
            ;;
          '$out/share/tauon')
            makeWrapperArgs[$i]="$out/share/tauon"
            ;;
        esac
      done
    '';
  });
}
