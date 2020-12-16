autocmd BufNewFile,BufRead *.m2 set filetype=macaulay2
autocmd FileType macaulay2 setlocal commentstring=--\ %s
setlocal iskeyword-=_
