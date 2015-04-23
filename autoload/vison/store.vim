"============================================================================
" FILE: autoload/vison/store.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')
let s:File = s:V.import('System.File')
let s:Filepath = s:V.import('System.Filepath')

function! vison#store#setup()
  for group_name in keys(g:vison_store_groups)
    let group_info = g:vison_store_groups[group_name]
    echo group_info
    if !has_key(group_info, 'type') || !has_key(s:store_loader, group_info.type)
      "TODO
      echom '[vison] invalid group_info. group_name: '.group_name
    endif
    call s:store_loader[group_info.type](group_name, group_info)
  endfor
endfunction

let s:store_loader = {}
function! s:store_loader.git(group_name, group_info)
  if !executable('git')
    echom '[vison] Git not installed. Skip loading.'
    return
  endif
  
  let target_dir = s:Filepath.join(g:vison_data_directory, a:group_name)
  if !isdirectory(target_dir)
    let cmd = 'git clone '.a:group_info.url.' '.target_dir
    let output_list = systemlist(cmd)
  else
    execute('lcd '.target_dir)
    let cmd = 'git pull -f origin master'
    let output_list = systemlist(cmd)
    lcd -
  endif
  echo output_list
endfunction

let s:store_base = {}
function! s:store_base.git(group_name, group_info)
endfunction

function! vison#store#register(group_name, type_name, lines)
  let file_name = s:Filepath.join(s:Filepath.join(g:vison_data_directory, a:group_name), a:type_name)
  call s:File.mkdir_nothrow(s:Filepath.join(g:vison_data_directory, a:group_name), 'p')
  "TODO directory check
  return writefile(a:lines, file_name)
endfunction

function! vison#store#get_catalog()
  let files = globpath(expand(g:vison_data_directory), '**/*.json')
  return split(files, "\n")
endfunction


