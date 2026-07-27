{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      # Parsers
      jq
      jnv # jq interactive viewer
      yq-go

      # Archives
      unrar
      unzip
      zip

      wakatime-cli # Development timer
      chezmoi # Dotfile management helper(1password cli integrated)
      fastfetch
      gnuplot_qt # graphing ulitity
    ]
    ++ lib.optionals stdenv.isLinux [
      unar
    ];

  programs.zellij = {
    enable = true;
    enableZshIntegration = false; # カスタム init で管理（セッション自動削除のため）
    settings = {
      theme = "catppuccin-mocha";
      show_startup_tips = false;
      # ターミナルが強制クローズ（SIGHUP 等）されたとき、
      # detach ではなく quit してサーバーを確実に終了させる
      on_force_close = "quit";
    };
  };

  home.shellAliases = {
    zj = "zellij";
  };
}
