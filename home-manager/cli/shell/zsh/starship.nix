{
  programs.starship = {
    enable = true;
    settings = {
      format = ''
      [┌─\[$username@$hostname\]](bold blue) $directory$cmd_duration$package$status
      [└─\[[\$](bold purple)\] <$git_branch>](bold blue) '';
      scan_timeout = 10;
      add_newline = false;
      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "bold bright-green";
      };
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol$hostname]($style)";
        style = "bold green";
      };
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style)";
        style = "bold blue";
      };
      directory = {
        truncation_length = 100;
        truncate_to_repo = false;
        truncation_symbol = "…/";
        format = ''[-](white) [\[[$path]($style)[$read_only]($read_only_style)\]](bold blue) '';
        style = "bold white";
      };
      cmd_duration = {
        format = ''[-](white) [\[[$duration]($style)\]](bold blue) '';
        style = "bold yellow";
      };
      package = {
        format = ''[-](white) [\[[$symbol$version]($style)\]](bold blue) '';
        style = "#563C17";
      };
      status = {
        format = ''[-](white) [\[[$symbol$status]($style)\]](bold blue) '';
      };
      # Nerd Font Symbols
      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      conda.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      git_branch.symbol = " ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = "⌘ ";
      hg_branch.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = " ";
      meson.symbol = "喝 ";
      nim.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      os.symbols = {
        Alpine = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "﯑ ";
        Gentoo = " ";
        HardenedBSD = "ﲊ ";
        Illumos = " ";
        Linux = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = " ";
        openSUSE = " ";
        OracleLinux = " ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        Redox = " ";
        Solus = "ﴱ ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Windows = " ";
      };
      package.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "ﳒ ";
      ruby.symbol = " ";
      rust.symbol = " ";
      scala.symbol = " ";
      spack.symbol = "🅢 ";
    };
  };
}