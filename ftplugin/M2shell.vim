if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" upper K yanks the word to the quotestar register then calls the help function
nnoremap <buffer> <silent> K "*yiw:call macaulay2#show_help(@*)<cr>
vnoremap <buffer> <silent> K "*y:call macaulay2#show_help(@*)<cr>
" <leader>K requires user input
nnoremap <buffer> <silent> <localleader>K :call macaulay2#show_help(input('Help for: '))<cr>
nnoremap <buffer> <silent> <cr> :call M2shell#present_mode()<cr>
nnoremap <buffer> <silent> <c-r> :let b:present_line=1<cr>
imap <buffer> <silent> <a-cr> :call M2shell#present_mode()<cr>

function! M2shell#present_mode()
    if !exists("b:present_line")
        let b:present_line = 1
    endif
    let l = b:present_line
    let shell_win = win_getid()
    if win_gotoid(b:parent_win) == 0 " the parent (M2 script) window is not visible
        exec b:parent_buf "sb"
        let clean_up = winnr()
    endif
    let line = getline(l)
    call chansend(b:M2shell_job, line."\n")
    exec win_gotoid(shell_win)
    if exists("clean_up")
        exec clean_up "close" 
        unlet clean_up
    endif
    let b:present_line += 1
    normal! G
    " exec "startinsert"
    " exec "stopinsert"
endfunction
    
