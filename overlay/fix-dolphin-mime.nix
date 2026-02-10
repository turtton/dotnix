# ORIGINAL: https://github.com/rumboon/dolphin-overlay/blob/main/default.nix
# This Nix overlay modifies the Dolphin file manager package (GPL-licensed)
# to fix its "Open with" menu functionality when running outside of KDE.
#
# This overlay is provided as-is and is intended for personal use or as a
# contribution to Nixpkgs. It is compatible with the GPL license of Dolphin.
#
# Copyright (c) 2025 rumboon
# This overlay is licensed under the terms of the MIT license.
#
# The modified package retains its original GPL license.

final: prev:
let
  dolphin-orig = prev.kdePackages.dolphin;
in
{
  kdePackages = prev.kdePackages // {
    dolphin = prev.symlinkJoin {
      name = "dolphin-${dolphin-orig.version}";
      paths = [ dolphin-orig ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/dolphin
        makeWrapper ${dolphin-orig}/bin/dolphin $out/bin/dolphin \
            --prefix XDG_CONFIG_DIRS : "${prev.libsForQt5.kservice}/etc/xdg" \
            --run "${prev.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental ${prev.libsForQt5.kservice}/etc/xdg/menus/applications.menu"
      '';
    };
  };
}
