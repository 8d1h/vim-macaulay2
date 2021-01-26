" Quit when a syntax file was already loaded.
if exists('b:current_syntax') | finish | endif

setlocal iskeyword-=_
setlocal iskeyword+='

syn include @macaulay2 syntax/macaulay2.vim
syn match M2Prompt "[io]\d\+ [=:] " contained
syn region M2Block start="^+-\++$\n|" end="^+-\++$\n\ze\n" keepend contains=M2Border,M2Prompt,M2code,M2OutputSecondary
syn region M2Code start="i\d\+ : " end="\ze|$\n\(^|*\s\+|$\|^+-\++$\)" keepend contains=@macaulay2,M2Border,M2Prompt contained
syn region M2OutputSecondary start="o\d\+ : " end="\ze\(|$\n^+-\++$\)" keepend contains=M2Border,M2Prompt contained
syn match M2Comment "--.*$" contains=M2Todo,@Spell,M2Border contained

syn match M2Border "^|" contained
syn match M2Border "|$" contained
syn match M2Border "^+-\++$" contained

syn match M2Separator "^[=\*]\+$"

hi link M2Separator Special
hi link M2Border Comment
hi link M2Prompt Comment
hi link M2OutputSecondary Comment

let b:current_syntax = 'M2help'
