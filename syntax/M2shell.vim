" Quit when a syntax file was already loaded.
if exists('b:current_syntax') | finish | endif

setlocal iskeyword-=_
setlocal iskeyword+='

syn include @macaulay2 syntax/macaulay2.vim
syn match M2Prompt "[io]\+\d\+ [=:]"
syn region M2Code start="i\+\d\+ : " end="\n\ze\(^$\|stdio\)" keepend contains=@macaulay2,M2Prompt
syn region M2OutputSecondary start="o\+\d\+ : " end="\n\ze\(^$\)" keepend contains=M2Prompt
syn region M2Error start="stdio:\d\+:\d\+:" end="\ze\(\n^$\)" extend

hi link M2Prompt Comment
hi link M2OutputSecondary Comment
hi link M2Error Error

let b:current_syntax = 'M2shell'
