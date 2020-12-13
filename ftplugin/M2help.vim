if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" lower h yanks the word to the register "h then calls the help function
nnoremap <buffer> <localleader>h "hyiw:call macaulay2#help(@h)<cr>
" upper H requires user input
nnoremap <buffer> <localleader>H :call macaulay2#help(input('Help for: '))<cr>
