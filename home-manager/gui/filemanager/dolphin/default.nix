{ pkgs, ... }:
let
  # KIO は cwd を引数で渡さずプロセスの作業ディレクトリとして設定するだけで、
  # single-instance の ghostty への D-Bus 引き継ぎではそれが失われる。
  # 既存インスタンスがある時は +new-window で cwd を明示転送する。
  dolphin-terminal = pkgs.writeShellScriptBin "dolphin-terminal" ''
    if ${pkgs.systemd}/bin/busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus NameHasOwner s com.mitchellh.ghostty 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'b true'; then
      exec ${pkgs.ghostty}/bin/ghostty +new-window --working-directory="$(pwd)"
    fi
    exec ${pkgs.ghostty}/bin/ghostty
  '';
in
{
  home.packages = with pkgs; [
    dolphin-terminal
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio-extras
    jetbrains-dolphin
    kdePackages.ark
  ];
  xdg.dataFile = {
    "dolphin" = {
      source = ./share;
      recursive = true;
    };
    "state/dolphinstaterc".source = ./dolphinstaterc;
  };
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "${pkgs.dolphin}/share/applications/org.kde.dolphin.desktop" ];
  };
}
