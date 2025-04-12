{ pkgs, ... }:
{
  imports = [ ./starship.nix ];
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      npm = "corepack npm";
      npx = "corepack npx";
      pnpm = "corepack pnpm";
      pnpx = "corepack pnpx";
    };

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
  };
}
