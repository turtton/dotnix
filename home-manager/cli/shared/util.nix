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
      # ターミナルが強制クローズ（SIGHUP 等）されたとき、
      # detach ではなく quit してサーバーを確実に終了させる
      on_force_close = "quit";
    };
  };

  # ターミナルを閉じたときに孤立したzellijセッションが溜まらないよう、
  # on_force_close = "quit" でSIGHUP時にサーバーごと終了させる。
  # detach（Ctrl+P+D）した場合はサーバーが残るので別タブからreattach可能。
  # このブロックは必ず zsh init の末尾に置くこと（exit するため後続 init が実行されない）。
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive && -t 0 && -t 1 && "$TERM" != "dumb" && -z "$ZELLIJ" ]]; then
      ${lib.getExe pkgs.zellij}
      exit
    fi
  '';
}
