{ pkgs, ... }:
let
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json
  plugins = [
    "ideavim"
    "nixidea"
    "github-copilot"
  ];
  applyPlugins = ide: with pkgs; (jetbrains.plugins.addPlugins ide plugins);
  patched-idea = with pkgs; (applyPlugins jetbrains.idea-ultimate);
  requiredLibPath = with pkgs; lib.makeLibraryPath [
    libGL
    udev
  ];
  # Override LD_LIBREARY_PATH for minecraft mod dev(requires udev and libGL)
  # https://github.com/Gerschtli/nix-config/blob/763a8f515701ccab125174d241c2331fb72071e3/home/programs/idea-ultimate.nix#L66
  # https://github.com/Gerschtli/nix-config/blob/763a8f515701ccab125174d241c2331fb72071e3/lib/wrap-program.nix#L4
  idea = pkgs.symlinkJoin {
    name = "idea-ultimate-wrapped";
    paths = [ patched-idea ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild =
      let
        desktopEntryPath = "/share/applications/idea-ultimate.desktop";
        path = "/bin/idea-ultimate";
      in
      ''
        # desktop entry
        if [[ -L "$out/share/applications" ]]; then
          rm "$out/share/applications"
          mkdir "$out/share/applications"
        else
          rm "$out${desktopEntryPath}"
        fi

        sed -e "s|Exec=${patched-idea + path}|Exec=$out${path}|" \
          "${patched-idea + desktopEntryPath}" \
          > "$out${desktopEntryPath}"

        wrapProgram "$out${path}" \
          --prefix LD_LIBRARY_PATH : ${requiredLibPath}
      '';
  };
  ides = with pkgs.jetbrains; [
    webstorm
    rust-rover
  ];
in
{
  home.packages = with pkgs; [
    android-studio
    # basically should not use toolbox because of issues(https://github.com/NixOS/nixpkgs/issues/240444) but useful to preview IDE 
    jetbrains-toolbox
  ]
  ++ (map (ide: (applyPlugins ide)) ides)
  ++ [ idea ];
  home.file.".ideavimrc".source = ./ideavimrc;
}
