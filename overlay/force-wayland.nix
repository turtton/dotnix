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
      claude-desktop = inputs.claude-desktop.packages.${system}.claude-desktop;
      claude-desktop-wayland = forceWaylandIme {
        name = claude-desktop.pname;
        package = claude-desktop;
        desktopName = "claude";
      };
    in
    # https://github.com/k3d3/claude-desktop-linux-flake/blob/2b66e50045c03060d3becea838c5b57e46bbfc40/flake.nix#L24
    # prev.buildFHSEnv {
    #   name = "claude-desktop";
    #   targetPkgs =
    #     pkgs: with pkgs; [
    #       docker
    #       glibc
    #       openssl
    #       nodejs
    #       uv
    #     ];
    #   runScript = "${claude-desktop-wayland}/bin/claude-desktop";
    # };
    claude-desktop-wayland;
}
