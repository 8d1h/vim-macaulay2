autocmd BufNewFile,BufRead *.m2 set filetype=macaulay2
autocmd FileType macaulay2 setlocal comments=b:--
autocmd FileType macaulay2 setlocal commentstring=--\ %s
