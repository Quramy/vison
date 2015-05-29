"============================================================================
" FILE: autoload/vison/store.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')
let s:File = s:V.import('System.File')
let s:Filepath = s:V.import('System.Filepath')
let s:List = s:V.import('Data.List')

function! vison#store#setup()
  if !isdirectory(g:vison_data_directory)
    call s:File.mkdir_nothrow(g:vison_data_directory, 'p')
  endif
  for group_name in keys(g:vison_store_groups)
    let group_info = g:vison_store_groups[group_name]
    echo group_info
    if !has_key(group_info, 'type') || !has_key(s:type_handler, group_info.type)
      "TODO
      echom '[vison] invalid group_info. group_name: '.group_name
    endif
    call s:type_handler[group_info.type].load(group_name, group_info)
  endfor
  let s:is_cached_catalog = 0
  call vison#store#get_catalog()
endfunction

let s:type_handler = {}
let s:type_handler.default = {}

function! s:type_handler.default.load(group_name, group_info)
  " noop
endfunction

function! s:type_handler.default.basedir(group_name, group_info)
  return [s:Filepath.join(g:vison_data_directory, 'default')]
endfunction

let s:type_handler.git = {}
function! s:type_handler.git.load(group_name, group_info)
  if !executable('git')
    echom '[vison] Git not installed. Skip loading.'
    return
  endif
  
  let target_dir = s:Filepath.join(g:vison_data_directory, a:group_name)
  if !has_key(a:group_info, 'url')
    echom '[vison] Store group whose type is git must "url" property. group_name: '.a:group_name
    return
  endif
  if !isdirectory(target_dir)
    echo '[vison] Clone '.a:group_info.url
    let cmd = 'git clone '.a:group_info.url.' '.target_dir
    let output_list = systemlist(cmd)
  else
    echo '[vison] Update '.a:group_info.url
    execute('lcd '.target_dir)
    let cmd = 'git pull -f origin master'
    let output_list = systemlist(cmd)
    lcd -
  endif
  echo output_list
endfunction

function! s:type_handler.git.basedir(group_name, group_info)
  let target_dir = s:Filepath.join(g:vison_data_directory, a:group_name)
  if has_key(a:group_info, 'basedir')
    return map(copy(a:group_info.basedir), 's:Filepath.join(target_dir, v:val)')
  else
    return [target_dir]
  endif
endfunction

function! vison#store#register(group_name, type_name, lines)
  let file_name = s:Filepath.join(s:Filepath.join(g:vison_data_directory, a:group_name), a:type_name)
  call s:File.mkdir_nothrow(s:Filepath.join(g:vison_data_directory, a:group_name), 'p')
  "TODO directory check
  return writefile(a:lines, file_name)
endfunction

" ### Catalog {{{
let [s:is_cached_catalog, s:cache_catalog] = [0, {}]
function! vison#store#get_catalog()
  if s:is_cached_catalog
    return s:cache_catalog
  end
  let basedirs = []
  let tmp_map = {}
  for group_name in keys(g:vison_store_groups)
    let group_info = g:vison_store_groups[group_name]
    if !has_key(group_info, 'type') || !has_key(s:type_handler, group_info.type)
      continue
    endif
    let handler = s:type_handler[group_info.type]
    let schemafiles = split(globpath(join(handler.basedir(group_name, group_info), ','), '**/*.json'), "\n")
    let s:cache_catalog[group_name] = {}
    for filename in schemafiles
      let schemaname = s:Filepath.basename(filename)
      let s:cache_catalog[group_name][schemaname] = filename
      if !has_key(tmp_map, schemaname)
        let tmp_map[schemaname] = [group_name, filename]
      endif
    endfor
    "let s:cache_catalog[group_name] = schemafiles
    " let basedirs = s:List.concat([basedirs, handler.basedir(group_name, group_info)])
  endfor

  let short_list = {}
  for schemaname in keys(tmp_map)
    "call add(short_list, tmp_map[schemaname][1])
    let short_list[schemaname] = tmp_map[schemaname][1]
  endfor
  let s:cache_catalog['$short'] = short_list
  " let files = globpath(join(basedirs, ','), '**/*.json')
  let s:is_cached_catalog = 1
  return s:cache_catalog
endfunction

function! vison#store#get_schemanames()
  let catalog = vison#store#get_catalog()
  let result = []
  for group_name in keys(catalog)
    for schemaname in keys(catalog[group_name])
      if group_name ==# '$short'
        call add(result, schemaname)
      else
        call add(result, group_name.'#'.schemaname)
      endif
    endfor
  endfor
  return result
endfunction

function! vison#store#get_schemafile(schemaname, mode)
  let tmplist = split(a:schemaname, '#')
  if len(tmplist) == 1
    let group_name = '$short'
    let schemaname = tmplist[0]
  elseif len(tmplist) == 2
    let group_name = tmplist[0]
    let schemaname = tmplist[1]
  else
    "TODO
    return [0, '']
  endif

  let catalog = vison#store#get_catalog()
  if has_key(catalog, group_name) && has_key(catalog[group_name], schemaname)
    return [1, catalog[group_name][schemaname]]
  endif

  return [0, '']
  
endfunction
" ### Catalog }}}

call vison#store#get_catalog()


