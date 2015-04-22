"============================================================================
" FILE: plugin/vison.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

" Preprocessing {{{
if exists('g:loaded_vison')
  finish
endif

let g:loaded_vison = 1

let s:save_cpo = &cpo
set cpo&vim
" Preprocessing }}}


" Postprocessing {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" Postprocessing }}}
