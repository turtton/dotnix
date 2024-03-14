inputs@{pkgs, lib, ...} : let
  # these settings expected structre
  # {
  #   plugins = [];
  # }
  pluginSettings = [
    (import ./nvim-cmp.nix inputs)
    (import ./skk.nix inputs)
  ];
in {
  plugins = with pkgs.vimPlugins; [
    {
      plugin = kanagawa-nvim;
      config = ''
      colorscheme kanagawa
      '';
    }
    vim-wakatime
    fidget-nvim
  ] ++ lib.flatten (map (data: data.plugins) pluginSettings);
}