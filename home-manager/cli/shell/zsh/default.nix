{
  config,
  pkgs,
  hostPlatform,
  ...
}:
{
  imports = [ ./starship.nix ];
  home.shell.enableZshIntegration = true;
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.8.0";
          sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
        };
      }
      # {
      #   name = "xiong-chiamiov-plus";
      #   file = "themes/xiong-chiamiov-plus.zsh-theme";
      #   src = pkgs.fetchgit {
      #     url = "https://github.com/ohmyzsh/ohmyzsh.git";
      #     rev = "4fd2af0a82e2826317d9551ecd8d5f44553828d7";
      #     sparseCheckout = [
      #       "themes"
      #     ];
      #     hash = "sha256-jCXBz5FAhGLusWBA9JMGcQ7mxDhOYC5PXyWHoV4OYz0=";
      #   };
      # }
    ];
    # Used for useful history systems
    oh-my-zsh = {
      enable = true;
      plugins = [ ];
      # Disabled by sharship
      # theme = "xiong-chiamiov-plus";
    };

    # Set XDG_RUNTIME_DIR env var for some applicatins(e.g. nix-direnv)
    initContent = pkgs.lib.optionalString hostPlatform.isDarwin ''
      export XDG_RUNTIME_DIR="''${TMPDIR%/}/xdg-runtime-dir"
      mkdir -p "$XDG_RUNTIME_DIR"
      chmod 700 "$XDG_RUNTIME_DIR"
    '';
  };
}
