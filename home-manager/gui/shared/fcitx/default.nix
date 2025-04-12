{ pkgs, ... }:
{
  i18n.inputMethod = {
    enabled = "fcitx5";
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
      file=${libskk}/share/skk/SKK-JISYO.L,mode=readonly,type=file
    '';
  };
}
