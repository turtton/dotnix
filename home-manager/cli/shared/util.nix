{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # Parsers
    jq
    jnv # jq interactive viewer
    yq-go

    # Archives
    unar
    unrar
    unzip
    zip

    wakatime-cli # Development timer
    chezmoi # Dotfile management helper(1password cli integrated)
    fastfetch
    gnuplot_qt # graphing ulitity
  ];

  programs.zellij = {
    enable = true;
    enableZshIntegration = false; # カスタム init で管理（セッション自動削除のため）
    settings = {
      theme = "catppuccin-mocha";
      show_startup_tips = false;
    };
  };

  # ターミナルを閉じたときに孤立したzellijセッションが溜まらないよう、
  # シェル終了時に対応セッションを自動削除する
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -z "$ZELLIJ" ]]; then
      _zellij_session="zsh-$$"
      trap 'zellij kill-session --yes "$_zellij_session" 2>/dev/null; unset _zellij_session' EXIT
      zellij --session "$_zellij_session"
      exit
    fi
  '';
}
