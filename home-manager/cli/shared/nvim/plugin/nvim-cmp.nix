{ pkgs, ...}: {
  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-cmp;
      config = ''
      require'cmp'.setup {
        sources = {
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' }
        },
        view = {
          entries = 'native'
        }
      }
      '';
      type = "lua";
    }
  ];
}