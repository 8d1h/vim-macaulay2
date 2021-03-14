if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" upper K yanks the word to the register k then calls the help function
nnoremap <buffer> <silent> K "kyiw:call macaulay2#show_help(@k)<cr>
vnoremap <buffer> <silent> K "ky:call macaulay2#show_help(@k)<cr>
" <leader>K requires user input
nnoremap <buffer> <silent> <localleader>K :call macaulay2#show_help(input('Help for: '))<cr>
" <ctrl-r> to reload the page (with possibly different printWidth)
nnoremap <buffer> <silent> <c-r> :call macaulay2#show_help(b:help_entry)<cr>
