" ---------- PLUGINS -------------- {{{

set nocompatible
filetype off

set rtp+=~/.vim/vim-plug
let path='~/.vim/plugged'

call plug#begin(path)

let s:delayed_initializers = []

function! s:add_delayed_initializer(init)
  call add(s:delayed_initializers, a:init)
endfunction

function! s:delayed_init()
  for Init in s:delayed_initializers
    call Init()
  endfor
endfunction

" change leader key
let mapleader=" "
let maplocalleader=" "

function! s:has_patch(version, patch)
  return version > a:version || (version == a:version && has('patch' . a:patch))
endfunction

function! s:plugin_installed(plugin)
  return has_key(g:plugs, a:plugin) && isdirectory(g:plugs[a:plugin].dir)
endfunction

" ---------- nerdtree ---------- {{{

if v:version >= 703

  Plug 'scrooloose/nerdtree'

  let g:NERDTreeMouseMode = 2
  let g:NERDTreeMapJumpLastChild = '<C-f>'
  let g:NERDTreeMapJumpFirstChild = '<C-b>'
  let g:NERDTreeMapJumpNextSibling = 'J'
  let g:NERDTreeMapJumpPrevSibling = 'K'
  let g:NERDMenuMode = 3
  let g:NERDTreeCascadeSingleChildDir = 0
  let g:NERDTreeRespectWildIgnore = 1

  augroup my_nerdtree_maps
    au!
    autocmd FileType nerdtree nmap <buffer> <C-v> s
    autocmd FileType nerdtree nmap <buffer> <C-x> i
    autocmd FileType nerdtree nmap <buffer> <C-p> k
    autocmd FileType nerdtree nmap <buffer> . I
    autocmd FileType nerdtree nmap <buffer> <leader><tab> q
    autocmd BufWinEnter NERD_tree_* let b:NERDTree._previousBuf = bufname('#')
    autocmd BufUnload NERD_tree_* unlet t:netrwNERDTree
    if s:has_patch(704, 605)
      autocmd BufWinLeave NERD_tree_* if bufexists(b:NERDTree._previousBuf) | let @# = bufnr(b:NERDTree._previousBuf) | endif
      autocmd BufWinEnter * if bufname('#') == bufname('%') && exists('b:_prev_buffer') | let @# = bufnr(b:_prev_buffer) | endif
    else
      autocmd BufWinLeave NERD_tree_* if bufexists(b:NERDTree._previousBuf) | exec 'b ' . b:NERDTree._previousBuf | b# | endif
      autocmd BufWinEnter * if bufname('#') == bufname('%') && exists('b:_prev_buffer') | exec 'b ' . b:_prev_buffer | b# | call setpos('.', b:_prev_pos) | endif
      autocmd BufWinLeave * let b:_prev_pos = getpos('.')
    endif
    autocmd BufWinEnter * if bufexists(bufnr('#')) | let b:_prev_buffer = bufname('#') | endif
  augroup END

  function! NERDTreeEnableOrToggle()
    try
      NERDTreeToggle
    catch
      silent! NERDTree
    endtry
  endfunction

  function! NERDTreeNewOrReuse()
    if exists('t:netrwNERDTree')
      exec "b " . t:netrwNERDTree
    else
      e .
      let t:netrwNERDTree = bufname('%')
    endif
  endfunction

  map <C-n> :<C-r>=&ft == 'nerdtree' ? 'normal q' : 'call NERDTreeNewOrReuse()'<CR><CR>

  function! NERDTreeFindCurrentBuffer()
    let path = expand("%:p")
    call NERDTreeNewOrReuse()
    try
      let p = g:NERDTreePath.New(path)
      if !p.isUnder(b:NERDTree.root.path)
        call b:NERDTree.changeRoot(g:NERDTreeDirNode.New(p.getParent(), b:NERDTree))
      endif
      let node = b:NERDTree.root.reveal(p)
      call node.putCursorHere(1,0)
    catch NERDTree.InvalidArgumentsError
      let path = fnamemodify(path, ':h')
      let p = g:NERDTreePath.New(path)
      let dir = g:NERDTreeDirNode.New(p, b:NERDTree)
      if !p.isUnder(b:NERDTree.root.path)
        call b:NERDTree.changeRoot(dir)
      endif
    endtry
    call b:NERDTree.render()
  endfunction

  nmap n :<C-r>=&ft == 'nerdtree' ? 'normal q' : 'call NERDTreeFindCurrentBuffer()'<CR><CR>

  function! s:runtime_nerdtree_mappings()
    try
      " seems that not on all versions it loads automatically
      runtime after/plugin/NERDTreeMappings.vim
    catch
    endtry
  endfunction

  call s:add_delayed_initializer(function('s:runtime_nerdtree_mappings'))

endif

" }}}

" ---------- undotree ---------- {{{

if v:version >= 703

  Plug 'mbbill/undotree'

  let g:undotree_SetFocusWhenToggle = 1

  nnoremap u :UndotreeToggle<CR>

endif

" }}}

" -------- vim-easymotion ------ {{{

if v:version >= 703
  Plug 'easymotion/vim-easymotion'

  if version >= 703
    nmap <leader>f <Plug>(easymotion-sn)

    let g:EasyMotion_off_screen_search = 0
    let g:EasyMotion_inc_highlight = 1
    let g:EasyMotion_history_highlight = 0
  endif
endif

" }}}

" ---------- completion -------- {{{

if v:version >= 800

  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  if s:plugin_installed('coc.nvim') && executable('node')
    " use <tab> for trigger completion and navigate to the next complete item
    function! s:check_back_space() abort
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~ '\s'
    endfunction

    inoremap <silent><expr> <Tab>
          \ pumvisible() ? "\<C-n>" :
          \ <SID>check_back_space() ? "\<Tab>" :
          \ coc#refresh()

    inoremap <silent><expr> <S-Tab>
          \ pumvisible() ? "\<C-p>" :
          \ coc#refresh()

    inoremap <silent><expr> <c-@> coc#refresh()

    autocmd FileType python nmap <buffer> <C-]> <Plug>(coc-definition)

  endif

endif

" }}}

" ------------ python ---------- {{{

Plug 'hynek/vim-python-pep8-indent'

" }}}

" ---------- ultisnips --------- {{{

if v:version >= 704 && ( has('python3') || has('python') )

  Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

  let g:UltiSnipsExpandTrigger = 'e'
  let g:UltiSnipsListSnippets = 's'
  let g:UltiSnipsJumpForwardTrigger = 'f'
  let g:UltiSnipsJumpBackwardTrigger = 'b'

  let g:UltiSnipsEditSplit = 'vertical'
  let g:UltiSnipsSnippetsDir = $DOTFILES_DIR . '/.vim/UltiSnips'

endif

" }}}

" --------- delimitMate -------- {{{

Plug 'Raimondi/delimitMate'

let delimitMate_expand_cr=1
let delimitMate_expand_space=1
let delimitMate_jump_expansion = 1
let delimitMate_balance_matchpairs=1
let delimitMate_matchpairs = "(:),[:],{:}"
let delimitMate_smart_matchpairs = '^\%(\w\|[£$]\|[^[:space:][:punct:]]\)'

au FileType python let b:delimitMate_nesting_quotes = ['"', "'"]

imap <C-k> <Plug>delimitMateJumpMany
imap <C-l> <Plug>delimitMateS-Tab
imap <C-h> <Plug>delimitMateS-BS
imap <C-j> <C-k><CR>

" }}}

" --------- text objects ------- {{{

Plug 'machakann/vim-swap'
Plug 'machakann/vim-sandwich'
Plug 'machakann/vim-textobj-delimited'

if s:plugin_installed('vim-sandwich')

  let g:sandwich_no_default_key_mappings = 1
  let g:operator_sandwich_no_default_key_mappings = 1
  let g:textobj_sandwich_no_default_key_mappings = 1

  function! s:init_vim_sandwich()
    runtime macros/sandwich/keymap/surround.vim

    omap ic <Plug>(textobj-sandwich-auto-i)
    xmap ic <Plug>(textobj-sandwich-auto-i)
    omap ac <Plug>(textobj-sandwich-auto-a)
    xmap ac <Plug>(textobj-sandwich-auto-a)

    omap ia <Plug>(textobj-sandwich-function-ip)
    xmap ia <Plug>(textobj-sandwich-function-ip)
    omap aa <Plug>(textobj-sandwich-function-ap)
    xmap aa <Plug>(textobj-sandwich-function-ap)
    omap if <Plug>(textobj-sandwich-function-i)
    xmap if <Plug>(textobj-sandwich-function-i)
    omap af <Plug>(textobj-sandwich-function-a)
    xmap af <Plug>(textobj-sandwich-function-a)

    let g:sandwich#recipes += [
      \   {
      \     'buns': ['(', ')'],
      \     'cursor': 'head',
      \     'command': ['startinsert'],
      \     'kind': ['add', 'replace'],
      \     'action': ['add'],
      \     'input': ['F']
      \   },
      \ ]

    let g:sandwich_function_patterns = {}
    let g:sandwich_function_patterns['_'] = [
          \   {
          \     'header' : '\<\h\k*',
          \     'bra'    : '(',
          \     'ket'    : ')',
          \     'footer' : '',
          \   },
          \ ]
    let g:sandwich_function_patterns['vim'] = [
          \   {
          \     'header' : '\C\<\%(\h\|[sa]:\h\|g:[A-Z]\)\k*',
          \     'bra'    : '(',
          \     'ket'    : ')',
          \     'footer' : '',
          \   },
          \ ]
    let g:sandwich_function_patterns['python'] = [
          \   {
          \     'header' : '\<\h\(\.\|\k\)*',
          \     'bra'    : '(',
          \     'ket'    : ')',
          \     'footer' : '',
          \   },
          \ ]
    let g:sandwich_function_patterns['cpp'] = [
          \   {
          \     'header' : '\<\h\([.>:]\|\k\)*',
          \     'bra'    : '(',
          \     'ket'    : ')',
          \     'footer' : '',
          \   },
          \ ]

  endfunction

  call s:add_delayed_initializer(function('s:init_vim_sandwich'))

  omap i, <Plug>(swap-textobject-i)
  xmap i, <Plug>(swap-textobject-i)
  omap a, <Plug>(swap-textobject-a)
  xmap a, <Plug>(swap-textobject-a)

endif

" }}}

" ---------- fzf/ctrlp --------- {{{

if !empty($VIM_FZF) && $VIM_FZF != "0"
  Plug 'junegunn/fzf', { 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
endif
Plug 'kien/ctrlp.vim'

let g:ctrlp_cmd = 'CtrlPMRU'
let g:ctrlp_working_path_mode = 'ra'

nmap <leader>b <C-b>

if !executable('fzf') || empty($VIM_FZF) || $VIM_FZF == "0"

  nnoremap <silent> <C-b> :CtrlPBuffer<CR>
  nnoremap <silent> <C-f> :CtrlP<CR>

else

  function! s:full_path(dir_or_file)
    " if fnamemodify() applied once, full_path may look like /blah/../ when a:dir_or_file is '..'
    return fnamemodify(fnamemodify(a:dir_or_file, ':p'), ':p')
  endfunction

  command! -nargs=? -complete=dir FilesBetterPrompt call fzf#vim#files(<q-args>, {
        \ 'source': 'ag -g "" --hidden -U --ignore .git/',
        \ 'options': '--preview "cat {}" --prompt "' . (<q-args> ? getcwd() : s:full_path(<q-args>)) . ' (Files)> "'
        \ })

  function! s:mru_list_without_nonexistent()
    if empty(expand('%')) || &readonly
      let mru_list = ctrlp#mrufiles#list()
    else
      let mru_list = ctrlp#mrufiles#list()[1:]
    endif
    let cwd = fnameescape(getcwd())
    call filter(mru_list, '!empty(findfile(v:val, cwd))')
    return mru_list
  endfunction

  function! s:git_files_if_in_repo()
    let expanded = expand('%:p:h')
    if ! exists('b:git_dir')
      let expanded = getcwd()
      return fzf#vim#files(expanded, {
            \ 'source': 'ag -g "" --hidden -U --ignore .git/',
            \ 'options': '--preview "cat {}" --prompt "' . expanded . ' (Files)> "'
            \ })
    else
      let git_root = fugitive#repo().tree()
      let save_cwd = fnameescape(getcwd())
      let cdCmd = (haslocaldir() ? 'lcd!' : 'cd!')
      try
        exec cdCmd . git_root
        call fzf#vim#gitfiles('', {
              \ 'options': '--preview "cat {}" --prompt "' . git_root . ' (GitFiles)> "'
              \ })
      finally
        exec cdCmd . save_cwd
      endtry
    endif
  endfunction

  function! s:git_root_or_cwd()
    return exists('b:git_dir') ? fugitive#repo().tree() : getcwd()
  endfunction

  function! s:all_files_git_root_or_cwd()
    let path = s:git_root_or_cwd()
    call fzf#vim#files(path, {
          \ 'source': 'ag -g "" --hidden -U --ignore .git/',
          \ 'options': '--preview "cat {}" --prompt "' . path . ' (Files)> "'
          \ })
  endfunction

  " expands path relatively to cwd or git root if possible
  " (similar to CtrlP plugin)
  function! s:relpath(filepath_or_name)
    let fullpath = fnamemodify(a:filepath_or_name, ':p')
    let save_cwd = fnameescape(getcwd())
    let cdCmd = (haslocaldir() ? 'lcd!' : 'cd!')
    try
      exec cdCmd . fnameescape(s:git_root_or_cwd())
      let ret = fnamemodify(fullpath, ':.')
    finally
      exec cdCmd . save_cwd
    endtry
    return ret
  endfunction

  function! s:ansi(str, col, bold)
    return printf("\x1b[%s%sm%s\x1b[m", a:col, a:bold ? ';1' : '', a:str)
  endfunction

  for [s:c, s:a] in items({'black': 30, 'red': 31, 'green': 32, 'yellow': 33, 'blue': 34, 'magenta': 35, 'cyan': 36})
    exec "function! s:".s:c."(str, ...)\n"
          \ "  return s:ansi(a:str, ".s:a.", get(a:, 1, 0))\n"
          \ "endfunction"
  endfor

  function! s:color_path(path)
    if a:path =~ '^/'
      return s:blue(a:path)
    else
      return s:yellow(a:path)
    endif
  endfunction

  let s:default_action = {
        \ 'ctrl-t': 'tab split',
        \ 'ctrl-x': 'split',
        \ 'ctrl-v': 'vsplit' }

  " below function is used in order to get actions like ctrl-v etc.
  " and to transform path to proper version
  function! s:mru_sink(lines)
    if len(a:lines) <= 1
      return
    endif
    let key = remove(a:lines, 0)
    let cmd = get(s:default_action, key, 'e')
    let save_cwd = fnameescape(getcwd())
    let cdCmd = (haslocaldir() ? 'lcd!' : 'cd!')
    try
      exec cdCmd . fnameescape(s:git_root_or_cwd())
      let full_path_lines = map(a:lines, 'fnameescape(fnamemodify(v:val, ":p"))')
    finally
      exec cdCmd . save_cwd
    endtry
    if len(a:lines) > 1
      augroup fzf_swap
        autocmd SwapExists *
              \ let v:swapchoice='o'
              \| let b:swapname = v:swapname
      augroup END
    endif
    let empty = empty(expand('%')) && line('$') == 1 && empty(getline(1)) && !&modified
    try
      for item in full_path_lines
        if empty
          exec 'e' item
          let empty = 0
        else
          exec cmd item
        endif
        if exists('b:swapname')
          augroup swap_exists_once
            autocmd InsertEnter <buffer>
                  \ echohl ErrorMsg
                  \| echom 'E325: swap file exists: ' . b:swapname
                  \| sleep 2
                  \| echohl None
                  \| autocmd! swap_exists_once
          augroup END
        endif
      endfor
    finally
      silent! autocmd! fzf_swap
    endtry
  endfunction

  function! s:fzf_mru()
    call fzf#run({
          \ 'source':  map(s:mru_list_without_nonexistent(), 's:color_path(s:relpath(v:val))'),
          \ 'sink*': function("s:mru_sink"),
          \ 'options': '-m -x +s --prompt "' . s:git_root_or_cwd() .
          \ ' (MRU)> " --ansi --expect='.join(keys(s:default_action), ','),
          \ 'down':    '40%'
          \ })
  endfunction

  function! s:ag_preview_height(bang)
    return (a:bang ? &lines : (&lines * 40 / 100)) - 2
  endfunction

  function! s:ag_in(bang, ...)
    let tokens  = a:000
    let ag_opts = join(filter(copy(tokens), 'v:val =~ "^-"'))
    let query   = (filter(copy(tokens), 'v:val !~ "^-"'))
    let save_cwd = fnameescape(getcwd())
    let cdCmd = (haslocaldir() ? 'lcd!' : 'cd!')
    " in case provided path is relative:
    " treat it as relative to dir of current file, not cwd
    try
      exec cdCmd . fnameescape(expand('%:p:h'))
      let dir = s:full_path(a:1)
    finally
      exec cdCmd . save_cwd
    endtry
    call fzf#vim#ag(join(query[1:], ' '), ag_opts . ' --ignore .git/', {
          \ 'dir': dir,
          \ 'options': '--nth=4.. -d: --preview "$DOTFILES_DIR/ag_fzf_preview_helper.sh {} ' . s:ag_preview_height(a:bang) . '" --prompt "' . dir . ' (Ag)> "'
          \ }, a:bang ? 1 : 0)
  endfunction

  function! s:ag_with_opts(bang, ...)
    let tokens  = a:000
    let ag_opts = join(filter(copy(tokens), 'v:val =~ "^-"'))
    let query   = join(filter(copy(tokens), 'v:val !~ "^-"'))
    let dir = s:git_root_or_cwd()
    call fzf#vim#ag(query, ag_opts . ' --ignore .git/', {
          \ 'dir': dir,
          \ 'options': '--nth=4.. -d: --preview "$DOTFILES_DIR/ag_fzf_preview_helper.sh {} ' . s:ag_preview_height(a:bang) . '" --prompt "' . dir . ' (Ag)> "'
          \ }, a:bang ? 1 : 0)
  endfunction

  command! GitFilesOrCwd call s:git_files_if_in_repo()

  command! FilesGitRootOrCwd call s:all_files_git_root_or_cwd()

  command! Mru call s:fzf_mru()

  command! -nargs=+ -complete=dir -bang Agin call s:ag_in(<bang>0, <f-args>)

  command! -nargs=* -bang Agcwd exec 'Agin<bang>'  getcwd() '<args>'
  command! -nargs=* -bang AgGitRootOrCwd call s:ag_with_opts(<bang>0, <f-args>)

  runtime after/plugin/overrideAg.vim

  cnoreabbrev ag Ag
  cnoreabbrev agin Agin
  cnoreabbrev agcwd Agcwd

  let g:ctrlp_map = ''

  nnoremap <C-p> :Mru<CR>
  nnoremap <C-b> :Buffers<CR>
  nnoremap <leader>g :GitFilesOrCwd<CR>
  nnoremap <leader>a :FilesGitRootOrCwd<CR>

  function! s:fzf_init()
    command! -nargs=* -bang Ag AgGitRootOrCwd<bang> <args>
    command! -nargs=? -complete=dir Files FilesBetterPrompt<bang> <args>
  endfunction

  call s:add_delayed_initializer(function('s:fzf_init'))
endif

" }}}

" ------------- git ------------ {{{

Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'

" }}}

" ------- better-whitespace ---- {{{

Plug 'ntpeters/vim-better-whitespace'

let g:better_whitespace_operator = ""

" }}}

" --------- colors/themes ------ {{{

Plug 'sjl/badwolf'
Plug 'w0ng/vim-hybrid'

Plug 'octol/vim-cpp-enhanced-highlight'

Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

let g:airline_left_sep=''
let g:airline_right_sep=''

let g:airline#extensions#whitespace#enabled = 0

let g:cpp_experimental_template_highlight = 1
let g:cpp_concepts_highlight = 1

" }}}

" ------------ tpope ----------- {{{

Plug 'tpope/vim-repeat'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-rsi'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-scriptease'
Plug 'tpope/vim-commentary'

nnoremap <F8> :Make<CR>
nnoremap <C-F8> :Make!<CR>
nnoremap <F9> :Dispatch<CR>
nnoremap <C-F9> :Dispatch!<CR>
nnoremap <F10> :Start<CR>
nnoremap <C-F10> :Start!<CR>

let g:nremap = {"m": ""}

autocmd FileType c,cpp setlocal commentstring=//\ %s

function! s:python_setlocal()
  augroup python_setlocal
    autocmd!
    autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4 tabstop=8
  augroup END
  if &ft == 'python'
  setlocal expandtab shiftwidth=4 softtabstop=4 tabstop=8
  endif
endfunction

call s:add_delayed_initializer(function('s:python_setlocal'))

" }}}

" --------- golden-ratio ------- {{{

Plug 'roman/golden-ratio'

" }}}

" ---------- easy-align -------- {{{

Plug 'junegunn/vim-easy-align'

xmap ga <Plug>(LiveEasyAlign)
nmap ga <Plug>(LiveEasyAlign)

" }}}

" ---------- incsearch --------- {{{

Plug 'haya14busa/incsearch.vim'

if s:plugin_installed('incsearch.vim')

  let g:incsearch#auto_nohlsearch = 1

  function! s:__enable_incsearch()
    map /  <Plug>(incsearch-forward)
    map ?  <Plug>(incsearch-backward)
    map g/ <Plug>(incsearch-stay)

    map n  <Plug>(incsearch-nohl-n)
    map N  <Plug>(incsearch-nohl-N)
    map *  <Plug>(incsearch-nohl-*)
    map #  <Plug>(incsearch-nohl-#)
    map g* <Plug>(incsearch-nohl-g*)
    map g# <Plug>(incsearch-nohl-g#)
  endfunction

  function! s:endisable_incsearch()
    if g:__incsearch_enabled == 0
      let g:__incsearch_enabled = 1
      call s:__enable_incsearch()
      set hlsearch
      set incsearch
      noh
      echo 'Better incsearch enabled'
    else
      let g:__incsearch_enabled = 0
      unmap /
      unmap ?
      unmap g/
      unmap n
      unmap N
      unmap *
      unmap #
      unmap g*
      unmap g#

      set nohlsearch
      set noincsearch

      echo 'Better incsearch disabled'
    endif
  endfunction

  call s:__enable_incsearch()
  if !exists('g:__incsearch_enabled')
    let g:__incsearch_enabled = 1
  endif

  nmap <silent> yo/ :call <SID>endisable_incsearch()<CR>

endif

" }}}

" ----------- clojure ---------- {{{

Plug 'guns/vim-sexp'
Plug 'tpope/vim-sexp-mappings-for-regular-people'
Plug 'tpope/vim-fireplace'
Plug 'junegunn/rainbow_parentheses.vim'

let g:sexp_mappings = {
      \ 'sexp_round_head_wrap_element':   '<LocalLeader>s',
      \ 'sexp_round_tail_wrap_element':   '<LocalLeader>S'
      \ }

augroup my_rainbow_au
  au!
  au FileType clojure RainbowParentheses
augroup END

let g:rainbow#colors = {
      \ 'dark': [
      \   ['brown', 'SaddleBrown'],
      \   ['blue', 'CornflowerBlue'],
      \   ['white', 'aquamarine2'],
      \   ['red', 'firebrick3'],
      \   ['yellow', 'goldenrod1'],
      \   ['magenta', 'DarkOrchid3'],
      \   ['red', 'PaleVioletRed2'],
      \ ]
      \ }

let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}']]

" }}}

" ------------ latex ----------- {{{


if !empty($VIM_LATEX) && $VIM_LATEX != "0"

  Plug 'lervag/vimtex'

  let g:tex_flavor = "latex"

  au FileType tex let b:delimitMate_quotes = "\" '"
  au FileType tex set textwidth=120

  augroup latexSurround
    autocmd!
    autocmd FileType tex call s:latexSurround()
  augroup END

  function! s:latexSurround()
    let b:surround_{char2nr("e")}
          \ = "\\begin{\1environment: \1}\n\t\r\n\\end{\1\1}"
    let b:surround_{char2nr("c")} = "\\\1command: \1{\r}"
  endfunction


endif

" }}}

call plug#end()

function! s:init_esc_mappings()
  " it has to be done after any other esc/alt bindings
  " alt + key send's esc sequence + key, so vim waits for key after esc when
  " something is mapped to alt + key, don't want it
  nnoremap <nowait> <esc> <esc>
  vnoremap <nowait> <esc> <esc>
  inoremap <nowait> <esc> <esc>
  cnoremap <nowait> <esc> <C-c>
  snoremap <nowait> <esc> <esc>
endfunction

call s:add_delayed_initializer(function('s:init_esc_mappings'))

function! s:did_vim_enter()
  if s:has_patch(704, 1658)
    return v:vim_did_enter
  else
    return exists('g:vimrc_init')
  endif
endfunction

if s:did_vim_enter()
  call s:delayed_init()
else
  au VimEnter * call s:delayed_init()
endif

filetype plugin indent on

" some options get overriden by plugins when re-sourcing vimrc, set them to
" desired values
runtime after/plugin/override.vim

" --------------- PLUGINS END --------------- }}}

" ---------- VIM OPTS ------------- {{{

" enable mouse if possible
if has('mouse')
  set mouse+=a
endif

" tmux options
if ( &term =~ '^screen' || &term =~ '^tmux' ) && exists('$TMUX')
  " tmux knows the extended mouse mode
  set ttymouse=xterm2
  " tmux will send xterm-style keys when xterm-keys is on
  exec "set <xUp>=\e[1;*A"
  exec "set <xDown>=\e[1;*B"
  exec "set <xRight>=\e[1;*C"
  exec "set <xLeft>=\e[1;*D"
  exec "set <xHome>=\e[1;*H"
  exec "set <xEnd>=\e[1;*F"
  exec "set <Insert>=\e[2;*~"
  exec "set <Delete>=\e[3;*~"
  exec "set <PageUp>=\e[5;*~"
  exec "set <PageDown>=\e[6;*~"
  exec "set <xF1>=\e[1;*P"
  exec "set <xF2>=\e[1;*Q"
  exec "set <xF3>=\e[1;*R"
  exec "set <xF4>=\e[1;*S"
  exec "set <F5>=\e[15;*~"
  exec "set <F6>=\e[17;*~"
  exec "set <F7>=\e[18;*~"
  exec "set <F8>=\e[19;*~"
  exec "set <F9>=\e[20;*~"
  exec "set <F10>=\e[21;*~"
  exec "set <F11>=\e[23;*~"
  exec "set <F12>=\e[24;*~"
endif

" mouse fix for columns > 220
if has('mouse_sgr')
  set ttymouse=sgr
endif

set clipboard-=autoselect
" set clipboard+=unnamed

" timeout for key codes (delayed ESC is annoying)
set ttimeoutlen=0

" enable persistent undo + its settings
if has("persistent_undo")
  if isdirectory($HOME . '/.vim/.undodir') == 0
    :silent !mkdir -p $HOME/.vim/.undodir >/dev/null 2>&1
  endif
  set undolevels=15000
  set undofile
  set undodir=$HOME/.vim/.undodir/
endif

if isdirectory($HOME . '/.vim/.backupdir') == 0
  :silent !mkdir -p $HOME/.vim/.backupdir >/dev/null 2>&1
endif
set backupdir=$HOME/.vim/.backupdir//
set backup

if isdirectory($HOME . '/.vim/.swapdir') == 0
  :silent !mkdir -p $HOME/.vim/.swapdir >/dev/null 2>&1
endif
set directory=$HOME/.vim/.swapdir//
set swapfile

" completion options
set completeopt=menuone

set novisualbell
if exists('+belloff')
  set belloff=all
endif

" Automatically read a file that has changed on disk
set autoread

" number of command line history lines kept
set history=10000

" default encoding
set encoding=utf-8

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" do incremental searching
set incsearch

" set search highlighting, bo do not highlight for now
set hlsearch
noh

" line endings settings
set fileformats=unix,dos

" always show status line
set laststatus=2

" allow to hide buffer with unsaved changes
set hidden

" no characters in separators
set fillchars=""

" disable that annoying beeping
autocmd GUIEnter * set vb t_vb=

" display incomplete commands
set showcmd

set lazyredraw

if (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8') && version >= 700
  let &listchars = "tab:»\ ,trail:\u2022"
else
  set listchars=tab:>\ ,trail:-,extends:>,precedes:<
endif
set list

set wildmenu
set wildmode=longest:full,full

" some options have to be set only at init
if !exists("g:vimrc_init")
  let g:vimrc_init = 1

  " enable syntax highlighting
  syntax on

  set updatetime=100

  set background=dark
  " silent! colorscheme hybrid
  silent! colorscheme jellybeans

  if has('termguicolors')
    set termguicolors
    let &t_8f = "[38;2;%lu;%lu;%lum"
    let &t_8b = "[48;2;%lu;%lu;%lum"
  endif

  set guioptions=Pci

  " when editing a file, always jump to the last known cursor position.
  autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   exe "normal! g`\"" |
        \ endif

  " 80/120 columns marker
  silent! let &colorcolumn="121"

  " indentation options
  set autoindent
  set expandtab
  set shiftwidth=2
  set softtabstop=2
  set tabstop=2
  set smarttab

  " line numbers
  set nonumber
  silent! set norelativenumber

  " set folding method
  set foldmethod=marker

  " diff options
  set diffopt+=vertical

  " split settings
  set splitbelow
  set splitright

  " show the cursor position all the time
  set ruler

  " show at least 5 lines below/above cursor
  set scrolloff=5
  set sidescrolloff=5
  set sidescroll=1

  set foldcolumn=0

  set nowrap

  set wildignore+=*.pyc,*.pyo
endif " exists("g:vimrc_init")

" Cstyle indentation settings
set cinoptions=
set cinoptions+=l1
set cinoptions+=g0
set cinoptions+=N-s
set cinoptions+=t0
set cinoptions+=(0
set cinoptions+=u0
" set cinoptions+=U1
" set cinoptions+=w1
set cinoptions+=W1s
set cinoptions+=k2s
set cinoptions+=m1
" set cinoptions+=M1
set cinoptions+=j1
set cinoptions+=J1

" Sometimes autocommands interfere with each other and break syntax
" Let's fix it
au! syntaxset BufEnter *

silent! set shortmess+=c

highlight ExtraWhitespace ctermbg=137 guibg=#cc4411

" hi! VertSplit guibg=#252525
" hi! MatchParen guifg=#5F5F87 guibg=#1d1f21
hi! clear TabLine
hi! clear TabLineFill
hi! TabLine guifg=#d5d8d6 guibg=#3c3c3c
hi! TabLineFill guifg=#d5d8d6 guibg=#3c3c3c

au BufReadPost,BufNewFile ~/.vimrc* set tw=0

" --------------- VIM OPTS END ------------- }}}

" ---------- VIM MAPPINGS --------- {{{

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

cabbrev Q q
cabbrev WQ wq
cabbrev Wq wq
cabbrev W w

function! s:toggleWindow(name)
  for i in range(1, winnr('$'))
    let bnum = winbufnr(i)
    if getbufvar(bnum, '&buftype') == 'quickfix'
      let dict = getwininfo(win_getid(i))
      if len(dict) > 0 && get(dict[0], 'quickfix', 0) && !get(dict[0], 'loclist', 0)
        cclose
      elseif len(dict) > 0 && get(dict[0], 'quickfix', 0) && get(dict[0], 'loclist', 0)
        lclose
      endif
      return
    endif
  endfor

  exec 'bot ' . a:name . 'open'
endfunction

" open/close quickfix/location-list window
noremap <silent> \q :call <SID>toggleWindow('c')<CR>
noremap <silent> \l :call <SID>toggleWindow('l')<CR>
noremap <silent> \c :call <SID>toggleWindow('C')<CR>

" moving around wrapped lines more naturally
noremap j gj
noremap k gk

" easier quitting
map <leader>q :q<CR>

" disable search highlighting
map <silent> <leader>n :noh<CR>

nmap <leader><tab> :b#<CR>

" save current file
map <leader>w :w<CR>

" quickly edit/reload the vimrc file
if $MYVIMRC == ""
  let $MYVIMRC = $HOME . '/.vimrc'
endif
nmap <silent> <leader>v :<C-R>=(expand('%:p')==$MYVIMRC)? 'so' : 'e'<CR> $MYVIMRC<CR>

" resizing splits more easily
nmap _ :exe "vertical resize " . ((winwidth(0) + 1) * 3/2)<CR>
nmap - :exe "vertical resize " . (winwidth(0) * 2/3)<CR>
nmap _ :exe "resize " . ((winheight(0) + 1) * 3/2)<CR>
nmap - :exe "resize " . (winheight(0) * 2/3)<CR>

nmap cy "+y
vmap cy "+y
nmap cY "+Y
vmap cY "+Y

nmap cp "+p
vmap cp "+p
nmap cP "+P
vmap cP "+P

nmap 0p "0p
vmap 0p "0p
nmap 0P "0P
vmap 0P "0P

nmap <leader>r "
vmap <leader>r "

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

autocmd FileType help nnoremap <nowait> <buffer> q :quit<CR>

nmap <silent> <leader>t :checktime<CR>

" refresh <nowait> ESC mappings
runtime after/plugin/ESCNoWaitMappings.vim

inoremap jj <esc>

function! MoveToPrevTab(...)
  let l:line = line('.')
  "there is only one window
  if tabpagenr('$') == 1 && winnr('$') == 1
    return
  endif
  "preparing new window
  let l:last = tabpagenr() == tabpagenr('$')
  let l:only = winnr('$') == 1
  let l:cur_buf = bufnr('%')
  if tabpagenr() != 1 && a:0 == 0
    close!
    if (!l:last && l:only) || !l:only
      tabprev
    endif
    vsp
  else
    close!
    exe tabpagenr() - 1 . "tabnew"
  endif
  "opening current buffer in new window
  exe "b".l:cur_buf
  exe l:line
endfunc

function! MoveToNextTab(...)
  let l:line = line('.')
  "there is only one window
  if tabpagenr('$') == 1 && winnr('$') == 1
    return
  endif
  "preparing new window
  let l:tab_nr = tabpagenr('$')
  let l:cur_buf = bufnr('%')
  if tabpagenr() < tab_nr && a:0 == 0
    close!
    if l:tab_nr == tabpagenr('$')
      tabnext
    endif
    vsp
  else
    close!
    tabnew
  endif
  "opening current buffer in new window
  exe "b".l:cur_buf
  exe l:line
endfunc

nnoremap <silent> t :tabnew %<CR>
nnoremap <silent> x :sp<CR>
nnoremap <silent> v :vsp<CR>

nnoremap <silent> . :call MoveToNextTab()<CR>
nnoremap <silent> , :call MoveToPrevTab()<CR>

nnoremap <silent> > :call MoveToNextTab(1)<CR>
nnoremap <silent> < :call MoveToPrevTab(1)<CR>

nnoremap h gT
nnoremap <silent> H :tabm-1<CR>
nnoremap l gt
nnoremap <silent> L :tabm+1<CR>

function! SourceRange() range
  let tmpsofile = tempname()
  call writefile(getline(a:firstline, a:lastline), l:tmpsofile)
  execute "source " . l:tmpsofile
  call delete(l:tmpsofile)
endfunction
command! -range Source <line1>,<line2>call SourceRange()

cnoremap <C-p> <up>
cnoremap <C-n> <down>

cnoremap <C-a> <C-b>
cnoremap b <C-Left>
cnoremap f <C-Right>

nnoremap <C-ScrollWheelUp> <ScrollWheelUp>
nnoremap <C-ScrollWheelDown> <ScrollWheelDown>
let s:wheel_mult = 5
exec 'nnoremap <M-ScrollWheelUp> ' . repeat('<ScrollWheelUp>', s:wheel_mult)
exec 'nnoremap <M-ScrollWheelDown> ' . repeat('<ScrollWheelDown>', s:wheel_mult)

" --------------- VIM MAPPINGS END -------------- }}}

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif

nmap <leader><leader>r :redraw!<CR>

nmap <leader>z <C-w>z<CR>

set formatoptions+=jl

abbrev flase false

nmap <silent>  :let @/=expand('<cword>') \| echo expand('<cword>')<CR>

function! SID(fname)
  redir => l:scriptnames
  sil exe 'scriptnames'
  redir END
  for script in split(l:scriptnames, "\n")
    if l:script =~ a:fname
      return str2nr(split(l:script, ":")[0])
    endif
  endfor
  return -1
endfunction

let s:swap_sid = SID('vim-swap/autoload/swap/textobj.vim')
if s:swap_sid == -1
  try
    let l:dummy = swap#textobj#dummy
  catch
  endtry
  let s:swap_sid = SID('vim-swap/autoload/swap/textobj.vim')
endif

let s:sandwich_sid = SID('vim-sandwich/autoload/sandwich/magicchar/f.vim')
if s:sandwich_sid == -1
  try
    let l:dummy = sandwich#magicchar#f#dummy
  catch
  endtry
  let s:sandwich_sid = SID('vim-sandwich/autoload/sandwich/magicchar/f.vim')
endif

function! AddArgument(where)
  let l:count = v:count1

  if index(['<', '>'], a:where) >= 0

    let TEXTOBJ = !!1
    let swap = swap#swap#new('n', [])
    let [buffer, rule] = swap.scan('char', TEXTOBJ)
    if empty(buffer) || empty(buffer.items)
      return
    endif
    let [start, end] = eval('<SNR>' . s:swap_sid . '_get_target_i(buffer, l:count)')
    if a:where ==# '>'
      let pos = end.region.tail
    elseif a:where ==# '<'
      let pos = start.region.head
    endif

  elseif index(['<<', '>>'], a:where) >= 0

    let opt = {}
    let opt.searchlines = eval('<SNR>' . s:sandwich_sid . '_get("textobj_sandwich_function_searchlines" , 30)')
    let pattern_list = eval('<SNR>' . s:sandwich_sid . '_resolve_patterns()')
    let view = winsaveview()
    try
      let candidates = eval('<SNR>' . s:sandwich_sid . '_gather_candidates("ap", l:count, pattern_list, opt)')
      let [start, end] = eval('<SNR>' . s:sandwich_sid . '_get_range("ap", l:count, candidates)')
      if start == [0, 0] || end == [0, 0]
        return
      endif
    finally
      call winrestview(view)
    endtry
    if a:where ==# '>>'
      let [line, col] = end
      let col += 1
    elseif a:where ==# '<<'
      let [line, col] = start
    endif
    let pos = [0, line, col, 0]

  endif

  call setpos('.', pos)
  if a:where[0] ==# '>'
    execute "normal! i, \<esc>l"
  elseif a:where[0] ==# '<'
    execute "normal! i, \<esc>h"
  endif
  startinsert

endfunction

nnoremap <silent> g,i :call AddArgument('<')<CR>
nnoremap <silent> g,a :call AddArgument('>')<CR>
nnoremap <silent> g,I :call AddArgument('<<')<CR>
nnoremap <silent> g,A :call AddArgument('>>')<CR>
