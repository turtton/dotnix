self: prev:
let
  append-env =
    {
      env,
      name,
      desktopName ? name,
      binaryNames ? [ name ],
    }:
    let
      targetPackege = prev.${name};
    in
    prev.symlinkJoin {
      inherit (targetPackege) pname version;
      name = "${name}-wrapped";
      paths = [ targetPackege ];
      buildInputs = [ prev.makeWrapper ];
      postBuild =
        let
          desktopEntryPath = "/share/applications/${desktopName}.desktop";
          paths = map (binaryName: "/bin/${binaryName}") binaryNames;
          seds = map (
            path:
            ''sed -e "s|Exec=${prev.${name} + path}|Exec=$out${path}|" "${
              prev.${name} + desktopEntryPath
            }" > "$out${desktopEntryPath}"''
          ) paths;
          wrapPrograms = map (path: ''wrapProgram "$out${path}" --prefix ${env}'') paths;
        in
        ''
                    			# desktop
                    			if [[ -L "$out/share/applications" ]]; then
                    				rm "$out/share/applications"
                    				mkdir -p "$out/share/applications"
                    			else
                    				rm "$out${desktopEntryPath}"
                    			fi

          								${prev.lib.concatStringsSep "\n" seds}

          								${prev.lib.concatStringsSep "\n" wrapPrograms}
                    		'';
    };
  fix-qt = args: append-env ({ env = ''QT_IM_MODULE : "wayland;fcitx"''; } // args);
  fix-gtk = args: append-env ({ env = ''GTK_IM_MODULE : "fcitx"''; } // args);
in
{
  zoom-us = fix-qt rec {
    name = "zoom-us";
    desktopName = "Zoom";
    binaryNames = [
      name
      "zoom"
    ];
  };
}
