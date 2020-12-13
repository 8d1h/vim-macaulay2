if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" omni completion
setlocal omnifunc=syntaxcomplete#Complete
let g:omni_syntax_group_include_macaulay2 = 'M2NameType,M2NameFunction,M2Other'

" lower h yanks the word to the register "h then calls the help function
nnoremap <buffer> <localleader>h "hyiw:call macaulay2#help(@h)<cr>
" upper H requires user input
nnoremap <buffer> <localleader>H :call macaulay2#help(input('Help for: '))<cr>
" r runs the script
nnoremap <buffer> <localleader>r :w !M2 --script %<cr>
" lower s opens an M2 shell and preloads the script
" upper S opens a clean M2 shell
if has('nvim')
    nnoremap <buffer> <silent> <localleader>s :w<cr>:vert rightb split \| term M2 %<cr>a
    nnoremap <buffer> <silent> <localleader>S :vert rightb split \| term M2 <cr>a
else
    nnoremap <buffer> <silent> <localleader>s :w<cr>:vert rightb term M2 %<cr>
    nnoremap <buffer> <silent> <localleader>S :vert rightb term M2 <cr>
endif

function! macaulay2#help(name)
    if &ft == "macaulay2"
        let wnr = bufwinnr("M2help")
        let bnr = bufnr("M2help")
        if wnr >= 0
            exec wnr "wincmd w"
        elseif bnr >= 0
            exec bnr "sb"
        else
            new
            setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap filetype=M2help nonumber norelativenumber 
            file M2help
        endif
    endif
    if empty(substitute(a:name,'\s\|\t','','g'))
        let str = '<< help()'
    elseif match(a:name, ',') == -1
        let str = '<< help \"'.a:name.'\"'
    else
        let str = '<< help('.a:name.')'
    endif
    if bufname() == "M2help"
        set modifiable
        %delete
        silent! execute '0$read !echo "'.str.'" > /tmp/M2help; M2 --script /tmp/M2help;'
        setlocal nomodifiable
        0
    endif
    if exists(":AirlineRefresh")
        exec ":AirlineRefresh"
    endif
endfunction

if exists(":AirlineRefresh")
    function! AirlineM2help(...)
        if &filetype == 'M2help'
            let w:airline_section_a = 'M2help'
            let w:airline_section_b = @h
            let w:airline_section_c = ''
        endif
    endfunction

    call airline#remove_statusline_func('AirlineM2help')
    call airline#add_statusline_func('AirlineM2help')
endif

