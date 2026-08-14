inputs: self: prev:
with prev;
let
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
  # nixpkgs only unsets DISPLAY under NIXOS_OZONE_WL; CEF needs the flag for fcitx
  spotify = prev.symlinkJoin {
    name = "spotify-wrapped";
    paths = [ prev.spotify ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/spotify" --add-flags "--enable-wayland-ime=true"
    '';
  };
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
