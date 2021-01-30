if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

if !exists("g:M2")
    let g:M2 = 'M2'
endif

let s:current_file=expand("<sfile>:p:h")

" omni completion
setlocal omnifunc=syntaxcomplete#Complete
let g:omni_syntax_group_include_macaulay2 = 'M2Datatype,M2Function,M2Symbol'

" lower h yanks the word to the register "h then calls the help function
nnoremap <buffer> <silent> <localleader>h "hyiw:call macaulay2#show_help(@h,b:macaulay2_env)<cr>
vnoremap <buffer> <silent> <localleader>h "hy:call macaulay2#show_help(@h,b:macaulay2_env)<cr>
" upper H requires user input
nnoremap <buffer> <silent> <localleader>H :call macaulay2#show_help(input('Help for: '),b:macaulay2_env)<cr>
" r runs the script
nnoremap <buffer> <silent> <localleader>r :exec 'w !'.g:M2.' --script %'<cr>
" lower s opens an M2 shell and preloads the script
" upper S opens a clean M2 shell
if has('nvim')
    nnoremap <buffer> <silent> <localleader>s :w<cr>:vert rightb split \| exec 'term '.g:M2.' %'<cr>a
    nnoremap <buffer> <silent> <localleader>S :vert rightb split \| exec 'term '.g:M2<cr>a
else
    nnoremap <buffer> <silent> <localleader>s :w<cr>:exec 'vert rightb term '.g:M2.' %'<cr>
    nnoremap <buffer> <silent> <localleader>S :exec 'vert rightb term '.g:M2<cr>
endif

function! macaulay2#show_help(name,env)
    if &ft == "macaulay2"
        let wnr = bufwinnr("M2help")
        let bnr = bufnr("M2help")
        if wnr >= 0
            exec wnr "wincmd w"
        elseif bnr >= 0
            exec bnr "sb"
        else
            new
            setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap nonumber norelativenumber 
            file M2help
        endif
    endif
    let b:macaulay2_env = a:env
    setlocal filetype=M2help
    let setwidth = 'printWidth = '.winwidth('%').';\n'
    let preamble = 'try needsPackage \\ {\"'.join(split(a:env,','), '\", \"').'\"};\n'
    if empty(substitute(a:name,'\s\|\t','','g'))
        let str = '<< help()'
    " elseif match(a:name, ',') == -1
    else
        let str = '<< help \"'.a:name.'\"'
    " commands like help(ideal,List)
    " else
        " let str = '<< help('.a:name.')'
    endif
    " check bufname before deletion!
    if bufname() == "M2help"
        set modifiable
        %delete
        silent! execute '0$read !echo "'.setwidth.preamble.str.'" > /tmp/vim-macaulay2; '.g:M2.' --script /tmp/vim-macaulay2;'
        setlocal nomodifiable
        0
    endif
    if exists(":AirlineRefresh")
        exec ":AirlineRefresh"
    endif
endfunction

function! s:syntax_update()
    execute '!echo "" > /tmp/vim-macaulay2;echo "" > /tmp/vim-macaulay2-syntax.vim;'
    " call writefile(['for x in Core#"exported symbols" do (if not member(toString x, set{"[","]","{","}","\\","^","_","|","~"}) then << "syn keyword M2" << class value x << " " << x << endl);'], glob('/tmp/vim-macaulay2'), 'a')
    for pkg in split(b:macaulay2_env,',')
        call writefile(['try(','    pkg = needsPackage "'.pkg.'";',
          \ '    << "if match(b:macaulay2_env, ''\\C'.pkg.''') != -1\n\tsyn keyword M2Symbol";',
          \ '    for x in pkg#"exported symbols" do (',
          \ '        if not instance(value x, Type) and not instance(value x, Function) then << " " << x;','    );',
          \ '    << " .\n\tsyn keyword M2Function";',
          \ '    for x in pkg#"exported symbols" do (',
          \ '        if instance(value x, Function) then << " " << x;','    );',
          \ '    << " .\n\tsyn keyword M2Datatype";',
          \ '    for x in pkg#"exported symbols" do (',
          \ '        if instance(value x, Type) then << " " << x;','    );',
          \ '    << " .\nendif\n";',');'], glob('/tmp/vim-macaulay2'), 'a')
    endfor
    if has('nvim')
        call jobstart(g:M2.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;', {'on_exit':{j,d,e->s:syntax_reload()}})
    else
        let s:job=job_start('sh -c "'.g:M2.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;"' , {'exit_cb':{j,s->s:syntax_reload()}})
    endif
endfunction

function! s:syntax_reload()
    setf macaulay2
    if exists("g:loaded_syntax_completion")
        unlet g:loaded_syntax_completion
    endif
    runtime autoload/syntaxcomplete.vim
endfunction

function! macaulay2#test()
    echo b:macaulay2_env
endfunction

function! macaulay2#env_update()
    if &filetype == "macaulay2" 
        if exists("b:macaulay2_env")
            let old_env = b:macaulay2_env
        endif
        let b:macaulay2_env = ""
        let pkgs = []
        let ptn = '^\(\(--\)\@!.\)*\<\%(load\|needs\)Package\(\(--\)\@!.\)\{-}\"\zs[^"]\+\ze\"'
        for line in getline(1, '$')
            let pkg = matchstr(line, ptn)
            while pkg != ""
                call add(pkgs, pkg)
                let line = substitute(line, '"'.pkg.'"', '', '')
                let pkg = matchstr(line, ptn)
            endwhile
        endfor
        let b:macaulay2_env = join(uniq(sort(split(b:macaulay2_env, ',')+pkgs)),',')
        if exists("old_env")
            if b:macaulay2_env != old_env
                call s:syntax_update()
            endif
        else
            call s:syntax_update()
        endif
    endif
endfunction

" update env
au BufEnter,TextChanged,InsertLeave *.m2 silent call macaulay2#env_update()

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

function! macaulay2#generate_symbols()
    if has('nvim')
        call jobstart("cd ".s:current_file."/../syntax/; ".g:M2." --script make-M2-symbols.m2;", {'on_exit':{j,d,e->s:syntax_reload()}})
    else
        let s:job=job_start('sh -c "cd '.s:current_file.'/../syntax/; '.g:M2.' --script make-M2-symbols.m2;"', {'exit_cb':{j,s->s:syntax_reload()}})
    endif
endfunction
