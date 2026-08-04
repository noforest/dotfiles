if exists("b:current_syntax")
  finish
endif

syntax keyword exaKeyword Action Fonction Variable Début Fin Renvoyer
syntax keyword exaType N R Booléen
syntax keyword exaBoolean VRAI FAUX

syntax match exaNumber "\<[0-9]\+\>"
syntax region exaString start='"' end='"'
syntax match exaComment "//.*"

highlight link exaKeyword Keyword
highlight link exaType Type
highlight link exaBoolean Boolean
highlight link exaNumber Number
highlight link exaString String
highlight link exaComment Comment

let b:current_syntax = "exa"
