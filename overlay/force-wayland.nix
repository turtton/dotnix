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
          # FHS packages (discord) ship $out/share as a store symlink; lndir
          # preserves it, and rm through it hits the read-only store
          if [[ -L "$out/share" ]]; then
          	share_target=$(readlink "$out/share")
          	rm "$out/share"
          	mkdir -p "$out/share"
          	for entry in "$share_target"/*; do
          		ln -s "$entry" "$out/share/"
          	done
          fi
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
      # The upstream flake builds claude-desktop-fhs with its own pinned
      # nixpkgs, so our fix-fhs-launcher overlay (dieWithParent=false)
      # cannot reach it. Rebuild the FHS env with OUR buildFHSEnv instead.
      # The base app does not involve buildFHSEnv, so it can be reused as-is.
      base = inputs.claude-desktop.packages.${stdenv.system}.claude-desktop;
      claude-desktop = prev.callPackage (inputs.claude-desktop + "/nix/fhs.nix") {
        claude-desktop = base;
      };
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
        cp --remove-destination "${claude-desktop}/share/applications/com.anthropic.Claude.desktop" "$out/share/applications/com.anthropic.Claude.desktop"
        wrapProgram "$out/bin/claude-desktop" --set CLAUDE_USE_WAYLAND 1
      '';
    };
}
