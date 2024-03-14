" fzf
" nnoremap <silent> <C-A-f> :FZF<CR>
" save as superuser
cnoremap <silent> w!! :w !sudo tee > /dev/null %<CR> :e!<CR>
" quick normal mode
inoremap <C-h> <ESC>
" change display
nmap <C-j> <c-w>j
nmap <C-w> <c-w>k
nmap <C-h> <c-w>h
nmap <C-l> <c-w>l
" split display
nmap sv <c-w>v
nmap ss <c-w>s
" quick redo
nmap U <c-R>

" Toggle case and start typing. E.g. `<leader>iget`: `property` -> `getProperty`
map <leader>i ~hi
" Remove selection and toggle case. E.g. `v2l<leader>u`: `getProperty` -> `property`
vmap <leader>u d~h

" Move visual line like{gjjj(up 3 visual line)}(https://zenn.dev/mattn/articles/83c2d4c7645faa)
nmap j gj<SID>g
nmap k gk<SID>g
nnoremap <script> <SID>gj gj<SID>g
nnoremap <script> <SID>gk gk<SID>g
nmap <SID>g <Nop>

" quick save
nmap <leader>w :w