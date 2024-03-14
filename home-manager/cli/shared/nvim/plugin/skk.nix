{ pkgs, ...}: let 
  skkeleton = pkgs.vimUtils.buildVimPlugin {
    name = "skkeleton";
    src = pkgs.fetchFromGitHub {
      owner = "vim-skk";
      repo = "skkeleton";
      rev = "342f71218dd08ad3053f141302db2fb1101f1213";
      hash = "sha256-umpBr09lMSng44PQ3jauWVEi1EuVJ1A9+dOlLAONbTw=";
    };
    dependencies = 
      with pkgs.vimPlugins; with pkgs; [ denops-vim skk-dicts ];
  };
  skkeleton-config = ''
  function! s:skkeleton_init() abort
	call skkeleton#config({
        \ 'eggLikeNewline': v:true,
        \ 'globalDictionaries': ["${pkgs.skk-dicts}/share/SKK-JISYO.L"],
        \ })
	call skkeleton#register_kanatable('rom', {
        \ "z\<Space>": ["\u3000", ''\],
        \ })
  endfunction
  augroup skkeleton-initialize-pre
    autocmd!
    autocmd User skkeleton-initialize-pre call s:skkeleton_init()
  augroup END

  imap <C-j> <Plug>(skkeleton-toggle)
  cmap <C-j> <Plug>(skkeleton-toggle)
  '';
  cmp-skkeleton = pkgs.vimUtils.buildVimPlugin {
    name = "cmp-skkeleton";
    src = pkgs.fetchFromGitHub {
      owner = "rinx";
      repo = "cmp-skkeleton";
      rev = "ae74491bc73b868c60f69e4362d3bea29a6bf74d";
      hash = "sha256-umpBr09lMSng44PQ3jauWVEi1EuVJ1A9+dOlLAONbTw=";
    };
    dependencies = with pkgs.vimPlugins; [ nvim-cmp ] ++ [skkeleton];
  };
  cmp-skkeleton-config = ''
  require'cmp'.setup.sources = require'cmp'.config.sources({
    { name = "skkeleton" }
  })
  '';
in {
  plugins = [
    {
      plugin = skkeleton;
      config = skkeleton-config;
    }
    {
      plugin = cmp-skkeleton;
      config = cmp-skkeleton-config;
      # https://github.com/nix-community/home-manager/blob/2f0db7d418e781354d8a3c50e611e3b1cd413087/modules/programs/neovim.nix#L26
      type = "lua";
    }
    cmp-skkeleton
  ];
}