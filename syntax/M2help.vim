" Quit when a syntax file was already loaded.
if exists('b:current_syntax') | finish | endif

syn include @macaulay2 syntax/macaulay2.vim
syn region M2Code start="^|\zsi\d\+" end="\ze\(^|\s\+|$\|^+-\++$\)" contains=@macaulay2,M2Border
syn match M2Comment "--.*$" contains=M2Todo,@Spell,M2Border contained
syn match M2Border "^|\||$" contained
syn match M2Separator "^[=\*]\+$"

hi link M2Separator Special

let b:current_syntax = 'M2help'
