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

" upper K yanks the word to the register k then calls the help function
nnoremap <buffer> <silent> K "kyiw:call macaulay2#show_help(@k)<cr>
vnoremap <buffer> <silent> K "ky:call macaulay2#show_help(@k)<cr>
" <leader>K requires user input
nnoremap <buffer> <silent> <localleader>K :call macaulay2#show_help(input('Help for: '))<cr>
" r runs the script
nnoremap <buffer> <silent> <localleader>r :exec 'w !'.g:M2.' --script %'<cr>
" lower s opens an M2 shell and preloads the script
" upper S opens a clean M2 shell
nnoremap <buffer> <silent> <localleader>s :M2Shell<cr>
nnoremap <buffer> <silent> <localleader>S :M2ShellClean<cr>
if has('nvim')
    " in nvim, <Enter> sends the current line / selected lines to the shell
    nnoremap <buffer> <silent> <cr> :call macaulay2#send_code(getline("."))<cr><cr>
    nnoremap <buffer> <silent> <a-cr> :call macaulay2#send_code(getline("."))<cr>
    vnoremap <buffer> <silent> <cr> "*y:call macaulay2#send_code(@*)<cr><cr>
    " <alt-r> restart the M2 shell (<ctrl-r> conflits with redo)
    nnoremap <buffer> <silent> <a-r> :call macaulay2#send_code("restart\n")<cr>
    " record the shell buffer number and the parent (M2 script) for each shell_id
    let s:M2shell_bufnrs = {}
    let s:M2shell_parents = {}
    " <leader>p enters the emacs-like presentation mode
    command -buffer M2Presentation :call macaulay2#init_shell(g:M2) | setlocal bufhidden=hide | close
    nnoremap <buffer> <silent> <localleader>p :M2Presentation<cr>
endif

" pack some of the functionalities as commands
command -buffer M2Shell :write | exec macaulay2#init_shell(g:M2.' '.@%) "wincmd w" | start
command -buffer M2ShellClean :exec macaulay2#init_shell(g:M2) "wincmd w" | start
command -buffer M2GenerateSymbols :call macaulay2#generate_symbols()

function! macaulay2#init_shell(cmd)
    if !has('nvim') " under vim only a shell is created
        exec 'vert rightb term '.a:cmd
    else
        let parent_win = winnr()
        let parent_buf = bufnr()
        let env = b:macaulay2_env
        " split and create the shell
        exec "rightb vnew"
        let job = termopen(a:cmd, {'on_exit': function('s:M2shell_exit')})
        let s:M2shell_bufnrs[job] = bufnr()
        let s:M2shell_parents[job] = parent_buf
        let shell_win = winnr()
        let b:parent_buf = parent_buf
        let b:macaulay2_env = env
        setlocal filetype=M2shell
        " switch back to the script
        exec parent_win "wincmd w"
        let b:M2shell_job = job
        return shell_win
    endif
endfunction

function! s:M2shell_exit(job,d,e)
    " delete the buffer of the shell if it still exists
    let M2shell_buf = s:M2shell_bufnrs[a:job]
    if bufexists(M2shell_buf)
        exec M2shell_buf "bd!"
    endif
    " switch back to the script and clean the refs
    let buf = bufnr()
    exec s:M2shell_parents[a:job] "b"
    if exists("b:M2shell_job")
        unlet b:M2shell_job
    endif
    exec buf "b"
    call remove(s:M2shell_bufnrs, a:job)
    call remove(s:M2shell_parents, a:job)
endfunction

function! macaulay2#send_code(code)
    if &filetype == "macaulay2"
        let lines = split(a:code, "\n")
        let non_empty = []
        for line in lines
            if substitute(line, '\s*\(--.*\)\?$', '', 'g') != ''
                call add(non_empty, line)
            endif
        endfor
        if non_empty == []
            return
        endif
        if !exists("b:M2shell_job")
            call macaulay2#init_shell(g:M2)
        endif
        " at this point the job and its buffer must both exist
        let job = b:M2shell_job
        let buf = s:M2shell_bufnrs[job]
        for line in non_empty
            call chansend(job, line."\n")
        endfor
        " set b:macaulay2_env and scroll the screen to bottom
        let parent_win = winnr()
        let env = b:macaulay2_env
        let wins = map(win_findbuf(buf), {k,v->win_id2win(v)})
        let win = 0
        for w in wins
            if w > 0
                exec w "wincmd w"
                let win = w
                break
            endif
        endfor
        if win == 0 " the shell is not visible on the tab
            exec "vert rightb" buf "sb"
        endif
        let b:macaulay2_env = env
        setlocal filetype=M2shell
        unlet g:loaded_syntax_completion
        runtime autoload/syntaxcomplete.vim
        normal! G
        " switch back to parent window
        exec parent_win "wincmd w"
    endif
endfunction

let s:M2help_bufs = []
function! macaulay2#show_help(name)
    if exists("b:macaulay2_env")
        let env = b:macaulay2_env
    else
        echo "Warning: the environment variable is not set"
        let env = ''
    endif
    if &ft == "macaulay2" || &ft == "M2shell"
        let win = 0
        let idx = 0
        for buf in s:M2help_bufs
            if !bufexists(buf)
                call remove(s:M2help_bufs, idx)
                continue
            endif
            if bufwinnr(buf) > 0
                let win = bufwinnr(buf)
                break
            endif
            let idx += 1
        endfor
        if win > 0
            exec win "wincmd w"
        else 
            new
            setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap nonumber norelativenumber 
            exec "file M2help-".bufnr()
            call add(s:M2help_bufs, bufnr())
        endif
    endif
    let b:macaulay2_env = env
    let b:help_entry = a:name
    setlocal filetype=M2help
    let preamble = 'printWidth = '.winwidth('%').';\n'
    for pkg in split(env,',')
        let preamble=preamble.'try needsPackage \"'.pkg.'\";\n'
    endfor
    if empty(substitute(a:name,'\s','','g'))
        let str = '<< help()'
    else
        let str = '<< help \"'.a:name.'\"'
    endif
    if bufname() == "M2help-".bufnr() " check bufname before deletion!!!
        setlocal modifiable
        %delete
        silent! exec '0$read !echo "'.preamble.str.'" > /tmp/vim-macaulay2; '.g:M2.' --script /tmp/vim-macaulay2;'
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
        call jobstart(g:M2.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;', {'on_exit':{j,d,e->s:syntax_reload(0)}})
    else
        let s:job=job_start('sh -c "'.g:M2.' --script /tmp/vim-macaulay2 > /tmp/vim-macaulay2-syntax.vim;"' , {'exit_cb':{j,s->s:syntax_reload(0)}})
    endif
endfunction

" .vim file is generated, needs to be reloaded
function! s:syntax_reload(notify)
    if a:notify
        echo "macaulay2.vim syntax file has been generated"
    endif
    setlocal filetype=macaulay2
    if exists("g:loaded_syntax_completion")
        unlet g:loaded_syntax_completion
    endif
    runtime autoload/syntaxcomplete.vim
endfunction

function! s:env_update()
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
au BufEnter,TextChanged,InsertLeave *.m2 silent call s:env_update()

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
            call jobstart("cd ".s:current_file."/../syntax/; ".g:M2." --script make-M2-symbols.m2;", {'on_exit':{j,d,e->s:syntax_reload(1)}})
        else
            let s:job=job_start('sh -c "cd '.s:current_file.'/../syntax/; '.g:M2.' --script make-M2-symbols.m2;"', {'exit_cb':{j,s->s:syntax_reload(1)}})
        endif
    endif
endfunction

" test function for printing values
function! macaulay2#test()
    echo "Hello there!"
    echo "b:macaulay2_env="
    echon b:macaulay2_env
    echo "M2help buffers: "
    echon s:M2help_bufs
    if has('nvim')
        echo "M2shell jobs and their parents: "
        echon s:M2shell_parents
    endif
endfunction
