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

if !exists('g:vison_data_directory')
  let g:vison_data_directory = expand('~/.cache/vison')
endif

command! -nargs=1 -complete=customlist,vison#switch_type_complete VisonSwitch call vison#switch_type(<f-args>)
command! -nargs=+ VisonRemoveSchema call vison#remove_schema(<f-args>)
command! -nargs=? VisonRegistSchema call vison#regist_default_schema(<f-args>)

" Postprocessing {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" Postprocessing }}}
