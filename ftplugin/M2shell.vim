if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" upper K yanks the word to the quotestar register then calls the help function
nnoremap <buffer> <silent> K "kyiw:call macaulay2#show_help(@k)<cr>
vnoremap <buffer> <silent> K "ky:call macaulay2#show_help(@k)<cr>
" <leader>K requires user input
nnoremap <buffer> <silent> <localleader>K :call macaulay2#show_help(input('Help for: '))<cr>
" normal mode: map <Enter> and <F11>
nnoremap <buffer> <silent> <cr> :call M2shell#present_mode(1)<cr>a<c-\><c-n>
nnoremap <buffer> <silent> <f11> :call M2shell#present_mode(1)<cr>a<c-\><c-n>
" insert mode: map <alt+Enter> and <F11>
if !has('nvim')
    exec "set <a-cr>=\<esc>\<cr>"
endif
tnoremap <buffer> <silent> <a-cr> <c-\><c-n>:call M2shell#present_mode(0)<cr>a
tnoremap <buffer> <silent> <f11> <c-\><c-n>:call M2shell#present_mode(0)<cr>a
" reload using <ctrl-r>
nnoremap <buffer> <silent> <c-r> :let b:present_line=1<cr>
tnoremap <buffer> <silent> <c-r> <c-\><c-n>:let b:present_line=1<cr>a

" check that current line has no input
function! s:no_input()
    let line = getline('.')
    return match(line, '^\(i\+\d\+ :\s*\|\s*\)$') == 0
endfunction

function! M2shell#present_mode(is_normal_mode)
    if !a:is_normal_mode && !s:no_input()
        " terminal mode with input => type Enter once
        if has('nvim')
            call chansend(b:terminal_job_id, "\n")
        else
            call term_sendkeys(bufnr(), "\n")
        end
        return
    endif
    if !exists("b:present_line")
        let b:present_line = 1
    endif
    let line = getbufline(b:parent_buf, b:present_line)
    if line == []
        let line = "-- end of buffer ".bufname(b:parent_buf)
    else
        let line = line[0]
        let b:present_line += 1
        if line == "" " if the line is empty, do the next line
            call M2shell#present_mode(a:is_normal_mode)
            return
        endif
    endif
    if a:is_normal_mode
        let line = line."\n"
    endif
    if has('nvim')
        call chansend(b:terminal_job_id, line)
    else
        call term_sendkeys(bufnr(), line)
    end
    syn sync fromstart
endfunction
    
