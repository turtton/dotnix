inputs: self: prev:
with prev;
let
  forceWaylandIme =
    {
      name,
      desktopName ? name,
      binaryNames ? [ name ],
      package ? null,
    }:
    let
      targetPackege = if package == null then prev.${name} else package;
    in
    prev.symlinkJoin {
      pname = targetPackege.pname or name;
      version = targetPackege.version or "unknown";
      name = "${name}-wrapped";
      paths = [ targetPackege ];
      buildInputs = [ prev.makeWrapper ];
      postBuild =
        let
          desktopEntryPath = "/share/applications/${desktopName}.desktop";
          paths = map (binaryName: "/bin/${binaryName}") binaryNames;
          seds = map (
            path:
            ''sed -e "s|Exec=${targetPackege + path}|Exec=$out${path}|" "${
              targetPackege + desktopEntryPath
            }" > "$out${desktopEntryPath}"''
          ) paths;
          wrapPrograms = map (
            path:
            ''wrapProgram "$out${path}" --add-flags "'--enable-wayland-ime' '--enable-features=UseOzonePlatform' '--ozone-platform=wayland'"''
          ) paths;
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
  overrideCommandLine =
    pkg:
    pkg.override {
      commandLineArgs = [
        "--enable-wayland-ime"
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    };
in
{
  vivaldi = overrideCommandLine prev.vivaldi;
  chromium = overrideCommandLine prev.chromium;
  google-chrome = overrideCommandLine prev.google-chrome;
  obsidian = overrideCommandLine prev.obsidian;
  vscode = overrideCommandLine prev.vscode;
  spotify = forceWaylandIme { name = "spotify"; };
  discord = forceWaylandIme rec {
    name = "discord";
    binaryNames = [
      name
      "Discord"
    ];
  };
  discord-ptb = forceWaylandIme {
    name = "discord-ptb";
    binaryNames = [
      "discordptb"
      "DiscordPTB"
    ];
  };
  slack = forceWaylandIme { name = "slack"; };
  teams-for-linux = forceWaylandIme { name = "teams-for-linux"; };
  claude-desktop =
    let
      claude-desktop = inputs.claude-desktop.packages.${stdenv.system}.claude-desktop-fhs;
    in
    prev.symlinkJoin {
      name = "claude-desktop-wrapped";
      paths = [ claude-desktop ];
      buildInputs = [ prev.makeWrapper ];
      meta = (claude-desktop.meta or { }) // {
        mainProgram = "claude-desktop";
      };
      postBuild = ''
        rm -f "$out/share/applications/claude-desktop.desktop" 2>/dev/null || true
        if [[ -L "$out/share/applications" ]]; then
          rm "$out/share/applications"
          mkdir -p "$out/share/applications"
        fi
        cp --remove-destination "${claude-desktop}/share/applications/claude-desktop.desktop" "$out/share/applications/claude-desktop.desktop"
        wrapProgram "$out/bin/claude-desktop" --set CLAUDE_USE_WAYLAND 1
      '';
    };
}
