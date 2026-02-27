{ pkgs, config, ... }:
let
  skk-dict-cleanup = pkgs.writeShellApplication {
    name = "skk-dict-cleanup";
    runtimeInputs = with pkgs; [
      gnused
      coreutils
    ];
    text = ''
      dict="$HOME/.local/share/fcitx5/skk/user.dict"
      if [ -f "$dict" ]; then
        tmp=$(mktemp)
        # 空白のみ・空の候補を除去し、候補がなくなった行を削除
        sed ':loop; s|/[[:space:]　]*/|/|g; t loop; /^[^ ][^ ]* \/$/d' "$dict" > "$tmp"
        mv "$tmp" "$dict"
      fi
    '';
  };
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-qt
      fcitx5-gtk
      fcitx5-skk
      libskk
      fcitx5-tokyonight
    ];
  };
  home.file = {
    ".xprofile".text = ''
      export GTK_IM_MODULE=fcitx
      export QT_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    '';
    ".config/fcitx5/config".source = ./config;
    ".config/fcitx5/conf/skk.conf".source = ./skk.conf;
    ".local/share/fcitx5/skk/dictionary_list".text = with pkgs; ''
      file=${config.home.homeDirectory}/.local/share/fcitx5/skk/user.dict,mode=readwrite,type=file
      file=${libskk}/share/skk/SKK-JISYO.L,mode=readonly,type=file
    '';
  };
  systemd.user.services.skk-dict-cleanup = {
    Unit.Description = "Clean up empty entries from SKK user dictionary";
    Service = {
      Type = "oneshot";
      ExecStart = "${skk-dict-cleanup}/bin/skk-dict-cleanup";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
