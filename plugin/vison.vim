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

" ### Global config {{{
if !exists('g:vison_data_directory')
  let g:vison_data_directory = expand('~/.cache/vison')
endif

if !exists('g:vison_store_groups')
  let g:vison_store_groups = {}
endif

let s:default_loader = {
      \ 'type': 'default'
      \ }

let s:ssloader = {
      \ 'type': 'git',
      \ 'url': 'https://github.com/SchemaStore/schemastore.git',
      \ 'basedir': ['src/schemas/json'],
      \ 'ignore': []
      \ }

let g:vison_store_groups.default = s:default_loader
let g:vison_store_groups.schema_store = s:ssloader
" ### Global config }}}

command! VisonSetup call vison#setup()
command! -nargs=* -complete=customlist,vison#switch_type_complete Vison call vison#switch_type(<f-args>)
command! -nargs=+ VisonRemoveSchema call vison#remove_schema(<f-args>)
command! -nargs=? VisonRegisterSchema call vison#register_default_schema(<f-args>)

" Postprocessing {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" Postprocessing }}}
