if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

if !exists("g:M2")
    let g:M2 = "M2"
endif

" the path for THIS file, ftplugin/macaulay2.vim
let s:current_file=expand("<sfile>:p:h")

" omni completion
setlocal omnifunc=syntaxcomplete#Complete
let g:omni_syntax_group_include_macaulay2 = 'M2Keyword,M2Datatype,M2Function,M2Symbol'

" upper K yanks the word to the quotestar register then calls the help function
nnoremap <buffer> <silent> K "*yiw:call macaulay2#show_help(@*)<cr>
vnoremap <buffer> <silent> K "*y:call macaulay2#show_help(@*)<cr>
" <leader>K requires user input
nnoremap <buffer> <silent> <localleader>K :call macaulay2#show_help(input('Help for: '))<cr>
" <leader>p enters the emacs-like presentation mode
nnoremap <buffer> <silent> <localleader>p :call macaulay2#init_shell(g:M2)<cr>:set hidden<cr>:close<cr>
" r runs the script
nnoremap <buffer> <silent> <localleader>r :exec 'w !'.g:M2.' --script %'<cr>
" lower s opens an M2 shell and preloads the script
" upper S opens a clean M2 shell
nnoremap <buffer> <silent> <localleader>s :w<cr>:call macaulay2#init_shell(g:M2.' '.@%)<cr>
nnoremap <buffer> <silent> <localleader>S :call macaulay2#init_shell(g:M2)<cr>
" in nvim, `return` sends the current line / selected lines to the shell
if has('nvim')
    nnoremap <buffer> <silent> <cr> :call macaulay2#send_code(getline("."))<cr><cr>
    nnoremap <buffer> <silent> <a-cr> :call macaulay2#send_code(getline("."))<cr>
    vnoremap <buffer> <silent> <cr> "*y:call macaulay2#send_code(@*)<cr><cr>
    " record the shell buffer number and the parent (M2 script) for each shell_id
    let s:M2shell_bufnrs = {}
    let s:M2shell_parents = {}
endif

function! macaulay2#init_shell(cmd)
    if !has('nvim') " under vim only a shell is created
        exec 'vert rightb term '.a:cmd
    else
        let code_win = win_getid()
        let code_buf = bufnr()
        let env = b:macaulay2_env
        " split and create the shell
        exec "belowright vnew"
        let M2shell_job = termopen(a:cmd, {'on_exit': function('s:M2shell_exit')})
        let M2shell_win = win_getid()
        let s:M2shell_bufnrs[M2shell_job] = bufnr()
        let s:M2shell_parents[M2shell_job] = code_win
        let b:parent_win = code_win
        let b:parent_buf = code_buf
        let b:macaulay2_env=env
        setlocal filetype=M2shell
        " switch back to the script
        exec win_id2win(code_win) "wincmd w"
        let b:M2shell_job = M2shell_job
        let b:M2shell_win = M2shell_win
    endif
endfunction

function! s:M2shell_exit(M2shell_job,d,e)
    " delete the buffer of the shell if it still exists
    let M2shell_buf = s:M2shell_bufnrs[a:M2shell_job]
    if bufexists(M2shell_buf)
        exec M2shell_buf "bd!"
    endif
    " switch back to the script and clean the refs
    exec win_id2win(s:M2shell_parents[a:M2shell_job]) "wincmd w"
    if exists("b:M2shell_job")
        unlet b:M2shell_job
    endif
    if exists("b:M2shell_win")
        unlet b:M2shell_win
    endif
endfunction

function! macaulay2#send_code(code)
    if &filetype == "macaulay2"
        let lines = split(a:code, "\n")
        let non_empty = []
        for line in lines
            if substitute(line, '\(\s\|\t\)*\(--.*\)\?$', '', 'g') != ''
                call add(non_empty, line)
            endif
        endfor
        if non_empty == []
            return
        endif
        if !exists("b:M2shell_job")
            call macaulay2#init_shell(g:M2)
        endif
        for line in non_empty
            call chansend(b:M2shell_job, line."\n")
        endfor
        " set b:macaulay2_env and scroll the screen to bottom
        let code_win = win_getid()
        let env = b:macaulay2_env
        if win_gotoid(b:M2shell_win) == 1
            let b:macaulay2_env=env
            setlocal filetype=M2shell
            unlet g:loaded_syntax_completion
            runtime autoload/syntaxcomplete.vim
            normal! G
            exec win_id2win(code_win) "wincmd w"
        endif
    endif
endfunction

function! macaulay2#show_help(name)
    if exists("b:macaulay2_env")
        let env = b:macaulay2_env
    else
        echo "Warning: the environment variable is not set"
        let env = ''
    endif
    if &ft == "macaulay2" || &ft == "M2shell"
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
    let b:macaulay2_env = env
    let b:help_entry = a:name
    setlocal filetype=M2help
    let setwidth = 'printWidth = '.winwidth('%').';\n'
    let preamble = 'try needsPackage \\ {\"'.join(split(env,','), '\", \"').'\"};\n'
    if empty(substitute(a:name,'\s\|\t','','g'))
        let str = '<< help()'
    else
        let str = '<< help \"'.a:name.'\"'
    endif
    if bufname() == "M2help" " check bufname before deletion!!!
        setlocal modifiable
        %delete
        silent! exec '0$read !echo "'.setwidth.preamble.str.'" > /tmp/vim-macaulay2; '.g:M2.' --script /tmp/vim-macaulay2;'
        setlocal nomodifiable
        0 " this moves cursor to top
    endif
    if exists(":AirlineRefresh")
        exec ":AirlineRefresh"
    endif
endfunction

" generate the .vim file for syntax
" keywords from Core should be handled by `generate_symbols`
" this treats only those from packages
function! s:syntax_update()
    exec '!echo "" > /tmp/vim-macaulay2;echo "" > /tmp/vim-macaulay2-syntax.vim;'
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
    " calling M2 is slow so we use async
    if has('nvim')
        call jobstart(g:M2.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;', {'on_exit':{j,d,e->s:syntax_reload()}})
    else
        let s:job=job_start('sh -c "'.g:M2.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;"' , {'exit_cb':{j,s->s:syntax_reload()}})
    endif
endfunction

" .vim file is generated, needs to be reloaded
function! s:syntax_reload()
    setlocal filetype=macaulay2
    if exists("g:loaded_syntax_completion")
        unlet g:loaded_syntax_completion
    endif
    runtime autoload/syntaxcomplete.vim
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
            let w:airline_section_b = b:help_entry
            let w:airline_section_c = ''
        endif
    endfunction
    call airline#remove_statusline_func('AirlineM2help')
    call airline#add_statusline_func('AirlineM2help')
endif

function! macaulay2#generate_symbols()
    if &filetype == "macaulay2" 
        if has('nvim')
            call jobstart("cd ".s:current_file."/../syntax/; ".g:M2." --script make-M2-symbols.m2;", {'on_exit':{j,d,e->s:syntax_reload()}})
        else
            let s:job=job_start('sh -c "cd '.s:current_file.'/../syntax/; '.g:M2.' --script make-M2-symbols.m2;"', {'exit_cb':{j,s->s:syntax_reload()}})
        endif
    endif
endfunction

" test function for printing values
function! macaulay2#test()
    echo "Hello there!"
    echo b:M2shell_id
    echo b:M2shell_nr
    echo s:M2shell_parents
endfunction
