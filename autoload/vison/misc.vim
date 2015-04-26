"============================================================================
" FILE: autoload/vison/store.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')
let s:JSON = s:V.import('Web.JSON')

function! vison#misc#load(fpath)
  if filereadable(a:fpath)
    let line_list = readfile(a:fpath)
    let json_string = join(line_list, ' ')
    return s:JSON.decode(json_string)
  endif
endfunction

function! vison#misc#log_warn(message)
  echohl WarningMsg
  echom '[vison] '.a:message
  echohl none
endfunction
