"============================================================================
" FILE: autoload/vison.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')
let s:Filepath = s:V.import('System.Filepath')
let s:base_dir = expand('<sfile>:p:h:h')

function! vison#base_dir()
  return s:base_dir
endfunction

function! vison#complete(findstart, base)
  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')
  
  " search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset 
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile

  if a:findstart
    let [b:type, b:query] = vison#resolver#get_query(getline(0, '$'))
    return l:start - 1
  else

    if b:type == -1
      return []
    elseif b:type == 0
      "TODO
      return []
    endif

    "TODO
    let schema_dict = vison#loader#file_loader(s:Filepath.join(s:base_dir, 'vest/schemas/package.json'))

    let lines = join(getline(0, '$'), '')
    let descriptors = vison#resolver#prop_descriptors(schema_dict, b:query, a:base)
    let result = []
    for description in descriptors
      let comp_item = {} 
      if b:type == 1
        let comp_item.word = '"'.description.name.'":'
      elseif b:type == 6
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




