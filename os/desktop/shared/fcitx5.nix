{pkgs, ...}:{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [kdePackages.fcitx5-qt fcitx5-gtk fcitx5-skk];
  };
}