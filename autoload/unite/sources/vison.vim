"============================================================================
" FILE: autoload/unite/sources/vison.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:source = {
      \ 'name': 'vison'
      \ }

function! s:source.gather_candidates(args, context)
  let catalog = vison#store#get_catalog()

  let buf_name = expand('%:p')
  "echo 'buffer: '.buf_name

  let result = []
  for group_name in keys(catalog)
    for schemaname in keys(catalog[group_name])
      if group_name ==# '$short'
        let word = schemaname
      else
        let word = group_name.'#'.schemaname
      endif
      call add(result, {
            \ 'word': word,
            \ 'source': 'vison',
            \ 'group': group_name,
            \ 'kind': 'command',
            \ 'action__command': 'Vison '.word.' '.buf_name
            \ })
    endfor
  endfor

  "return [{'word': 'hoge', 'source': 'vison', 'kind': 'jump_list'}]
  return result
endfunction

function! unite#sources#vison#define()
  return s:source
endfunction

