" manpager.vim - vim as $MANPAGER, keeping the bold and the italic.
"
" Vim ships a plugin of the same name ($VIMRUNTIME/plugin/manpager.vim). It
" emulates `col -b` and deletes the ANSI sequences, so by the time the man
" syntax runs, every word roff marked up is an ordinary word: a path, a scope
" name and a command name all look alike. This one reads the markup before
" cleaning it and paints it back as text properties.
"
" It takes the place of the shipped plugin by claiming its guard variable, so
" the documented invocation does not change:
"
"     export MANPAGER="vim +MANPAGER --not-a-term -"
"
" Both forms of markup are read: `c\bc` overstrike, which GROFF_NO_SGR=1
" produces, and the SGR escapes man emits by default.
"
" Headings keep the colours of the man syntax rather than these: they are bold
" too, and painting them here would flatten a page into a single colour.

if exists('g:loaded_manpager_plugin')
  finish
endif
let g:loaded_manpager_plugin = 1

command! MANPAGER call s:ManPager()

" The attribute in force after an SGR code, given the one before it.
function! s:Attr(code, cur) abort
  for p in split(a:code, ';', 1)
    if p ==# '' || p ==# '0' || p ==# '22' || p ==# '23' || p ==# '24'
      return ''
    elseif p ==# '1'
      return 'manBold'
    elseif p ==# '3'
      return 'manItalic'
    elseif p ==# '4'
      return 'manUnderline'
    endif
  endfor
  return a:cur
endfunction

" A line in, the same line without its markup and the ranges that carried it,
" as [byte column, byte length, property type].
"
" Walking character by character was the obvious way and the wrong one: a page
" like open(2) took seconds. Both forms are read from marker to marker instead,
" and the text between two markers is copied whole.
function! s:Parse(raw) abort
  if stridx(a:raw, "\<Esc>") >= 0
    " Both at once happens with no man in practice. Rather than a third parser,
    " the overstrike is dropped and the escapes are kept.
    let line = stridx(a:raw, "\<C-h>") >= 0 ? substitute(a:raw, '.\%x08', '', 'g') : a:raw
    return s:ParseSgr(line)
  elseif stridx(a:raw, "\<C-h>") >= 0
    return s:ParseOverstrike(a:raw)
  endif
  return [a:raw, []]
endfunction

" The escapes man emits by default. The text between two of them carries one
" attribute, so it is appended in one piece.
function! s:ParseSgr(raw) abort
  let out = ''
  let ranges = []
  let cur = ''
  let pos = 0
  while 1
    let [code, b, e] = matchstrpos(a:raw, "\<Esc>\[[0-9;]*m", pos)
    let chunk = b < 0 ? strpart(a:raw, pos) : strpart(a:raw, pos, b - pos)
    if chunk !=# ''
      if cur !=# ''
        call add(ranges, [strlen(out) + 1, strlen(chunk), cur])
      endif
      let out .= chunk
    endif
    if b < 0
      break
    endif
    let cur = s:Attr(strpart(code, 2, strlen(code) - 3), cur)
    let pos = e
  endwhile
  return [out, ranges]
endfunction

" The overstrike of a teletype, which GROFF_NO_SGR=1 produces: `c\bc` for bold,
" `_\bc` and `c\b_` for italic. Whole runs are matched, and only inside a run
" is anything looked at unit by unit.
function! s:ParseOverstrike(raw) abort
  let out = ''
  let ranges = []
  let pos = 0
  while 1
    let [run, b, e] = matchstrpos(a:raw, '\%(.\%x08.\)\+', pos)
    if b < 0
      break
    endif
    let out .= strpart(a:raw, pos, b - pos)
    let units = split(run, '\zs')
    let type = ''
    let text = ''
    let i = 0
    while i + 2 < len(units) + 1
      let lead = units[i]
      let over = units[i + 2]
      let kind = (lead ==# '_' || over ==# '_') ? 'manItalic' : 'manBold'
      if kind !=# type
        if type !=# ''
          call add(ranges, [strlen(out) + 1, strlen(text), type])
          let out .= text
        endif
        let type = kind
        let text = ''
      endif
      let text .= lead ==# '_' ? over : lead
      let i += 3
    endwhile
    if type !=# ''
      call add(ranges, [strlen(out) + 1, strlen(text), type])
      let out .= text
    endif
    let pos = e
  endwhile
  let out .= strpart(a:raw, pos)
  return [out, ranges]
endfunction

" Left to the man syntax: the header and footer lines, the section headings in
" column zero and the subheadings indented by three.
function! s:IsHeading(line) abort
  return a:line =~# '^\s\{0,3\}\S'
endfunction

" Green for what you type, yellow for what it acts on, as in `dot status`.
" Italic and underline share a colour on purpose: groff renders an italic as an
" underline on a terminal, so `.I` arrives as one or the other depending on the
" page and the version, and two colours for one intention would read as noise.
" `highlight def` leaves any definition of your own alone.
function! s:Colours() abort
  highlight def manBold      cterm=bold ctermfg=114 gui=bold   guifg=#a6e3a1
  highlight def manItalic    cterm=NONE ctermfg=180 gui=italic guifg=#f9e2af
  highlight def manUnderline cterm=NONE ctermfg=180 gui=NONE   guifg=#f9e2af
endfunction

function! s:ManPager() abort
  " Global options, kept to a minimum to avoid side effects.
  if &compatible
    set nocompatible
  endif
  if exists('+viminfofile')
    set viminfofile=NONE
  endif
  syntax on

  setlocal foldcolumn& nofoldenable nonumber norelativenumber
  " In case vim was invoked with -M.
  setlocal modifiable

  " Sequences that display nothing: OSC 8 hyperlinks, and the bell.
  silent! keepjumps keeppatterns %s/\v\e\]8;[^\x07\e]*%(\%x07|\e\\)//ge
  silent! keepjumps keeppatterns %s/\%x07//ge

  " Empty lines above the header, which the man syntax pins to line one.
  call cursor(1, 1)
  let first = search('.*(.*)', 'c')
  if first > 1
    execute '1,' . (first - 1) . 'delete _'
  endif

  let lines = []
  let found = []
  for raw in getline(1, '$')
    let [text, ranges] = s:Parse(raw)
    call add(lines, text)
    call add(found, ranges)
  endfor

  " The man syntax reads the SYNOPSIS of a section 2 or 3 page as C and colours
  " it as such, on this exact condition (see syntax/man.vim). A property drawn
  " over that would repaint the block in one colour and lose the types, the
  " strings and the comments, so the markup is left out of it. Elsewhere, and
  " on every other section, a SYNOPSIS is prose and keeps its markup.
  let ccode = !empty(lines) && lines[0] =~# '^[a-zA-Z_]\+([23])'
  let marks = []
  let synopsis = 0
  let lnum = 1
  for text in lines
    if text =~# '^SYNOPSIS'
      let synopsis = 1
    elseif text =~# '^\S'
      let synopsis = 0
    endif
    if !(ccode && synopsis) && !s:IsHeading(text)
      for r in found[lnum - 1]
        call add(marks, [lnum] + r)
      endfor
    endif
    let lnum += 1
  endfor
  call setline(1, lines)

  " Text properties draw over the syntax, so the markup survives without
  " fighting it. Vim 8.2 and later; anything older simply reads the page clean.
  if exists('*prop_type_add')
    " Before the types: a property type refuses a highlight group that does
    " not exist yet.
    call s:Colours()
    for type in ['manBold', 'manItalic', 'manUnderline']
      if empty(prop_type_get(type))
        call prop_type_add(type, {'highlight': type})
      endif
    endfor
    for m in marks
      call prop_add(m[0], m[1], {'length': m[2], 'type': m[3]})
    endfor
  endif

  " Finished preprocessing, prevent any further modification.
  setlocal nomodified nomodifiable
  setlocal buftype=nofile noswapfile bufhidden=hide nobuflisted readonly

  setlocal filetype=man
  runtime ftplugin/man.vim
endfunction
