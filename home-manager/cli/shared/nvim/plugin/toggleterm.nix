{ pkgs, ...}: {
  plugins = with pkgs.vimPlugins; [
    {
      plugin = toggleterm-nvim;
      config = ''
      require'toggleterm'.setup {
        size = 20,
        open_mapping = [[<c-t>]],
        direction = 'float',
      }
      '';
      type = "lua";
    }
  ];
}