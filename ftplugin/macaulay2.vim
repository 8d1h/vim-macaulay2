if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

if !exists("g:M2_bin")
    let g:M2_bin = 'M2'
endif

" omni completion
setlocal omnifunc=syntaxcomplete#Complete
let g:omni_syntax_group_include_macaulay2 = 'M2Type,M2Function,M2Symbol,M2Other'

" lower h yanks the word to the register "h then calls the help function
nnoremap <buffer> <silent> <localleader>h "hyiw:call macaulay2#help(@h,b:macaulay2_env)<cr>
vnoremap <buffer> <silent> <localleader>h "hy:call macaulay2#help(@h,b:macaulay2_env)<cr>
" upper H requires user input
nnoremap <buffer> <silent> <localleader>H :call macaulay2#help(input('Help for: '),b:macaulay2_env)<cr>
" r runs the script
nnoremap <buffer> <silent> <localleader>r :exec 'w !'.g:M2_bin.' --script %'<cr>
" lower s opens an M2 shell and preloads the script
" upper S opens a clean M2 shell
if has('nvim')
    nnoremap <buffer> <silent> <localleader>s :w<cr>:vert rightb split \| exec 'term '.g:M2_bin.' %'<cr>a
    nnoremap <buffer> <silent> <localleader>S :vert rightb split \| exec 'term '.g:M2_bin<cr>a
else
    nnoremap <buffer> <silent> <localleader>s :w<cr>:exec 'vert rightb term '.g:M2_bin.' %'<cr>
    nnoremap <buffer> <silent> <localleader>S :exec 'vert rightb term '.g:M2_bin<cr>
endif

function! macaulay2#help(name,env)
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
    let preamble = 'try needsPackage \"'.join(split(a:env,','), '\";try needsPackage \"').'\";'
    if empty(substitute(a:name,'\s\|\t','','g'))
        let str = '<< help()'
    elseif match(a:name, ',') == -1
        let str = '<< help \"'.a:name.'\"'
    " commands like help(ideal,List)
    else
        let str = '<< help('.a:name.')'
    endif
    " check bufname before deletion!
    if bufname() == "M2help"
        set modifiable
        %delete
        silent! execute '0$read !echo "'.preamble.str.'" > /tmp/vim-macaulay2; '.g:M2_bin.' --script /tmp/vim-macaulay2;'
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
        call writefile(['try(pkg = needsPackage "'.pkg.'";<< "if match(b:macaulay2_env, ''\\C'.pkg.''') != -1\nsyn keyword M2Type";for x in pkg#"exported symbols" do ( if class value x === Type then << " " << x;);<< " .\nsyn keyword M2Function";for x in pkg#"exported symbols" do ( if member(class value x,set{MethodFunction,MethodFunctionSingle,MethodFunctionBinary,MethodFunctionWithOptions}) then << " " << x;);<< " .\nsyn keyword M2Symbol";for x in pkg#"exported symbols" do ( if class value x === Symbol then << " " << x;);<<" .\nendif\n";);'], glob('/tmp/vim-macaulay2'), 'a')
    endfor
    if has('nvim')
        call jobstart(g:M2_bin.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;', {'on_exit':{j,d,e->s:syntax_reload()}})
    else
        let s:job=job_start('sh -c "'.g:M2_bin.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;"' , {'exit_cb':{j,s->s:syntax_reload()}})
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
    call s:syntax_update()
endfunction

function! macaulay2#env_update()
    if &filetype == "macaulay2" 
        if exists("b:macaulay2_env")
            let old_env = b:macaulay2_env
        endif
        let b:macaulay2_env = ""
        for line in getline(1, '$')
            let pkg = matchstr(line,'^\(\(--\)\@!.\)*\<\%(load\|needs\)Package.*\"\zs.\+\ze\"')
            if pkg != ""
                let b:macaulay2_env = join(uniq(sort(split(b:macaulay2_env, ',')+[pkg])),',')
            endif
        endfor
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

