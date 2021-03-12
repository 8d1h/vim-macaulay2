if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" upper K yanks the word to the quotestar register then calls the help function
nnoremap <buffer> <silent> K "*yiw:call macaulay2#show_help(@*)<cr>
vnoremap <buffer> <silent> K "*y:call macaulay2#show_help(@*)<cr>
" <leader>K requires user input
nnoremap <buffer> <silent> <localleader>K :call macaulay2#show_help(input('Help for: '))<cr>
