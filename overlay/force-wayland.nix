self: prev: with prev; let
  enableWaylandIme = { name, desktopName ? name, binaryName ? name }: prev.symlinkJoin {
    name = "${name}-wrapped";
    paths = [ prev.${name} ];
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
in
{
  vivaldi = enableWaylandIme { name = "vivaldi"; desktopName = "vivaldi-stable"; };
  spotify = enableWaylandIme { name = "spotify"; };
  obsidian = enableWaylandIme { name = "obsidian"; };
  discord = enableWaylandIme { name = "discord"; binaryName = "Discord"; };
  discord-ptb = enableWaylandIme { name = "discord-ptb"; binaryName = "DiscordPTB"; };
  slack = enableWaylandIme { name = "slack"; };
  teams-for-linux = enableWaylandIme { name = "teams-for-linux"; };
}
