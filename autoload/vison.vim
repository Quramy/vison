"============================================================================
" FILE: autoload/vison.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')
let s:File = s:V.import('System.File')
let s:Filepath = s:V.import('System.Filepath')
let s:base_dir = expand('<sfile>:p:h:h')

function! vison#base_dir()
  return s:base_dir
endfunction

" ### Complete {{{
function! vison#complete(findstart, base)
  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')
  
  " Search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset 
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile

  if a:findstart
    " Get query from the current buffer.
    let [b:type, b:query] = vison#resolver#get_query(getline(0, l:line))
    return l:start - 1
  else

    if b:type == -1
      return []
    elseif b:type == 0
      "TODO
      return []
    endif

    let [matched, schema_path] = vison#detect_schema(exists('b:schema_type') ? b:schema_type : '')
    if !matched
      echom "[vison] Can't find schema."
      return []
    endif
    let schema_dict = vison#loader#file_loader(schema_path)

    let descriptors = vison#resolver#prop_descriptors(schema_dict, b:query, a:base)
    let result = []
    for description in descriptors
      let comp_item = {} 
      if b:type == 1
        " User is going to write key string.
        let comp_item.word = '"'.description.name.'":'
      elseif b:type == 6
        " Uset is writing key string.
        let comp_item.word = description.name.'":'
      else
        let comp_item.word = description.name
      endif
      if has_key(description.descriptor, 'description') 
        let comp_item.menu = description.descriptor.description
      endif
      call add(result, comp_item)
    endfor
    return result
  endif
endfunction
" ### Complete }}}

" ### Switch schema type {{{
function! vison#switch_type(schema_type)
  let b:schema_type = a:schema_type
  setlocal omnifunc=vison#complete
endfunction

function! vison#switch_type_complete(ArgLead, CmdLine, CursorPos)
  let key_list = vison#get_schemanames()
  let matched = []
  for key_str in key_list
    if stridx(key_str, a:ArgLead) == 0
      call add(matched, key_str)
    endif
  endfor 
  return matched
endfunction
" ### Switch Schema type }}}

" ## Management shemas {{{
" ### Register {{{
function! vison#regist_schema(group_name, type_name)
  if a:type_name == ''
    echom '[vison] Schema name is empty.'
    return
  endif

  let file_name = s:Filepath.join(s:Filepath.join(g:vison_data_directory, a:group_name), a:type_name)
  call s:File.mkdir_nothrow(s:Filepath.join(g:vison_data_directory, a:group_name), 'p')
  call writefile(getline(0, '$'), file_name)
endfunction

function! vison#regist_default_schema(...)
  if a:0 > 1
    let type_name = a:1
  else
    let type_name = expand('%:t')
  endif
  call vison#regist_schema('default', type_name)
endfunction
" ### Register }}}

" ### Detection {{{
function! vison#detect_schema(schema_type)
  let catalog = vison#get_catalog()
  if !len(catalog)
    return [0, '']
  endif

  if a:schema_type == ''
    let schema_name = expand('%:t')
    let mode = 1
  else
    let schema_name = a:schema_type
    let mode = 0
  endif

  let [matched, result_path] = [0, '']

  let defaults = []
  for filepath in catalog
    if stridx(filepath, s:Filepath.join(expand(g:vison_data_directory), 'default')) == 0
      call add(defaults, filepath)
    else
      if vison#match_schema(schema_name, filepath, mode)
        let [matched, result_path] = [1, filepath]
      endif
    endif
  endfor

  for filepath in defaults
    if vison#match_schema(schema_name, filepath, mode)
      let [matched, result_path] = [1, filepath]
      break
    endif

    "let file_base = s:Filepath.basename(filepath)
    "echo file_base
    "if file_base == self_base
    "  let [matched, result_path] = [1, filepath]
    "  break
    "endif
  endfor
  return [matched, result_path]
endfunction

function! vison#match_schema(schema_type, filename, mode)
  let file_base = s:Filepath.basename(a:filename)
  if file_base == a:schema_type
    let matched = 1
    return 1
  endif
  if a:mode
    "TODO
  endif
  return 0
endfunction
" ### Detection }}}

function! vison#get_schemanames()
  let catalog = vison#get_catalog()
  let tmp_map = {}
  if len(catalog)
    for filename in catalog
      let tmp_map[s:Filepath.basename(filename)] = 1
    endfor
  endif
  return keys(tmp_map)
endfunction

function! vison#get_catalog()
  let files = globpath(expand(g:vison_data_directory), '**/*.json')
  return split(files, "\n")
endfunction

" ## Management shemas }}}

let g:vison_group_register = {}

let s:ssloader = {
      \ 'git': 'https://github.com/SchemaStore/schemastore.git',
      \ 'base': 'src/schemas/json',
      \ 'ignore': []
      \ }

let g:vison_group_register.schemastore = s:ssloader

function! s:complete_core()
  " underscore charactor stands for the cursor position.
  " case 1: {_
  "   should complete enbale key names.
  "   {query: '', base: ''}
  " case 2: { "ho_
  "   should complete enable key names.
  "   {query: '', base: 'ho'}
  " case 3: { "hoge"_
  "   should nothing. User may type ':' charactor.
  "   {query: 'hoge', base: ''}
  " case 4: { "hoge" :_
  "   should complete enable strings or '[' or '{'.
  "   {query: 'hoge', base: ''}
  " case 5: { "hoge" : "f\"o_
  "   {query: 'hoge', base: 'f\"o'}
  "   should complete enable strings.
  " case 6: { "hoge" : [_
  "   should complete enable strings or '{'.
  "   {query: 'hoge[0]', base: ''}
  " case 7: { "hoge": { "foo": [{ "bar": "pi_
  "   {query: 'hoge.foo[0].bar', base: 'pi'}
  " case 8: { "hoge" : ["foo", "ba_
  "   should complete enable strings or '{'.
  "   {query: 'hoge[0]', base: 'ba'}
  "
  " Algorithm
  " { "hoge": { "foo": [{ "bar": "pi_
  " to 
  " [ '{', ' "hoge"', ':', '{', " foo", ':', '[', '{', ' "bar"', ':', '"pi_']
endfunction

