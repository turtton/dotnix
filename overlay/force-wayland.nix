self: prev: with prev; let
  forceWaylandIme = { name, desktopName ? name, binaryName ? name }:
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
          path = "/bin/${binaryName}";
        in
        ''
          			# desktop
          			if [[ -L "$out/share/applications" ]]; then
          				rm "$out/share/applications"
          				mkdir -p "$out/share/applications"
          			else
          				rm "$out${desktopEntryPath}"
          			fi

          			sed -e "s|Exec=${prev.${name} + path}|Exec=$out${path}|" \
          				"${prev.${name} + desktopEntryPath}" \
          				> "$out${desktopEntryPath}"

          			wrapProgram "$out${path}" \
          				--add-flags "'--enable-wayland-ime' '--enable-features=UseOzonePlatform' '--ozone-platform=wayland'"
          		'';
    };
  overrideCommandLine = pkg: pkg.override { commandLineArgs = [ "--enable-wayland-ime" "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ]; };
in
{
  vivaldi = overrideCommandLine prev.vivaldi;
  chromium = overrideCommandLine prev.chromium;
  obsidian = overrideCommandLine prev.obsidian;
  vscode = overrideCommandLine prev.vscode;
  spotify = forceWaylandIme { name = "spotify"; };
  discord = forceWaylandIme { name = "discord"; binaryName = "Discord"; };
  discord-ptb = forceWaylandIme { name = "discord-ptb"; binaryName = "DiscordPTB"; };
  slack = forceWaylandIme { name = "slack"; };
  teams-for-linux = forceWaylandIme { name = "teams-for-linux"; };
}
