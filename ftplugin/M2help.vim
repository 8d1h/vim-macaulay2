if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" lower h yanks the word to the register "h then calls the help function
nnoremap <buffer> <silent> <localleader>h "hyiw:call macaulay2#help(@h,b:macaulay2_env)<cr>
vnoremap <buffer> <silent> <localleader>h "hy:call macaulay2#help(@h,b:macaulay2_env)<cr>
" upper H requires user input
nnoremap <buffer> <silent> <localleader>H :call macaulay2#help(input('Help for: '),b:macaulay2_env)<cr>
