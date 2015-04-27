"============================================================================
" FILE: autoload/vison/resolver.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')

function! s:get_as_str(dict, key)
  if has_key(a:dict, a:key)
    return join([a:dict[a:key]])
  else
    return ''
  endif
endfunction

function! s:has_match(dict, key, needle)
  if !has_key(a:dict, a:key)
    return -1
  end
  return match(a:dict[a:key], a:needle)
endfunction

" ### Walking Nodes {{{
function! vison#resolver#resolve_reference(node, root_dict)
  if !has_key(a:node, '$ref')
    return [1, a:node]
  endif
  let query = map(split(a:node['$ref'], '/'), '{"key": v:val, "enumerable": -1}')
  if !len(query)
    return [0, {}]
  endif
  if query[0].key !=# '#'
    return [0, {}]
  endif
  call remove(query, 0)
  "echo query
  return vison#resolver#get_node(a:root_dict, a:root_dict, query)
endfunction

function! vison#resolver#get_node(node, root_dict, query)
  let [parent, matched] = [a:node, 1]
  " Visit for part of queries
  for prop in a:query
    if s:has_match(parent, 'type', 'array') != -1
      if prop.key !=# '$array'
        return [0, {}]
      endif
      if !has_key(parent, 'items')
        return [0, {}]
      endif
      let parent = parent.items
      continue
    endif
    if prop.key ==# 'definitions'
      if has_key(parent, 'definitions')
        let parent = {'properties': parent.definitions, 'type': 'object'}
        continue
      else
        return [0, {}]
      endif
    elseif s:has_match(parent, 'type', 'object') != -1
      if prop.enumerable != -1 && prop.enumerable != 0  " Object
        return [0, {}]
      endif
      if !has_key(parent, 'properties') || !has_key(parent.properties, prop.key)
        return [0, {}]
      endif
      let [matched, parent] = vison#resolver#resolve_reference(parent.properties[prop.key], a:root_dict)
    else 
      return [0, {}]
    endif
  endfor
  return [matched, parent]
endfunction
" ### Walking Nodes }}}

" ### Get description {{{
function! vison#resolver#prop_descriptors(json_dict, query, base)
  let result = []
  let [matched, node] = vison#resolver#get_node(a:json_dict, a:json_dict, a:query)
  if !matched || !has_key(node, 'properties')
    return result
  endif
  for prop_name in keys(node.properties)
    if a:base !=# '' && stridx(prop_name, a:base) != 0
      continue
    endif
    let [matched, desc] = vison#resolver#resolve_reference(node.properties[prop_name], a:json_dict)
    if matched
      call add(result, {'name': prop_name, 'descriptor': desc})
    endif
  endfor

  return result
endfunction
" ### Get description }}}

" ### parse JSON {{{
function! vison#resolver#get_query(lines)
  let joined = join(a:lines, '')
  let mode = 0
  let buf = ''
  let buf_list = []
  let is_obj = 0
  let is_array = 0

  let l = strlen(joined)
  let i = 0

  while i < l
    let c = joined[i]
    if c ==# ' ' && mode != 6 && mode != 8
      let i = i + 1
      continue
    endif
    if mode == 0 "value start
      if c ==# '"'
        let mode = 8
      elseif c ==# '{'
        let is_obj = is_obj + 1
        let mode = 1
      elseif c ==# '['
        if len(buf_list)
          "let buf_list[len(buf_list) - 1].enumerable = 1
          call add(buf_list, {'key': '$array', 'enumerable': 1})
        endif
        let is_array = is_array + 1
      elseif c ==# 't' " is matched false
        if joined[(i):(i + 3)] ==# 'true'
          let i = i + 4
          let mode = 10
          continue
        else
          "echom 'invalid'
          let mode = -1
          break
        endif
      elseif c ==# 'f' " is matched false
        if joined[(i):(i + 4)] ==# 'false'
          let i = i + 5
          let mode = 10
          continue
        else
          "echom 'invalid'
          let mode = -1
          break
        endif
      elseif c ==# 'n' " is matched  null
        if joined[(i):(i + 3)] ==# 'null'
          let i = i + 4
          let mode = 10
          continue
        else
          "echom 'invalid'
          let mode = -1
          break
        endif
      elseif c ==# '-' || match(c, '\d') != -1 " number?
        let mode = 2
      else
        let mode = -1
        break
      endif
    elseif mode == 1
      if c !=# '"'
        echom 'invalid'
        break
      endif
      let mode = 6
    elseif mode == 2 "number
      if c ==# ','
        if is_array
          let mode = 10
        else
          call remove(buf_list, len(buf_list) - 1)
          let mode = 1
        endif
      elseif c ==# '}'
        call remove(buf_list, len(buf_list) - 1)
        let is_obj = is_obj - 1
        let mode = 10
      elseif c ==# ']'
        let is_array = is_array - 1
        let mode = 10
      endif
    elseif mode == 3
      if c !=# ':'
        "echom 'invalid'
        let mode = -1
        break
      endif
      let mode = 0
    elseif mode == 6  "key string
      if c ==# '\'
        let buf = buf.c
        let mode = 7
      elseif c ==# '"'
        call add(buf_list, {'key': buf, 'enumerable': 0})
        let buf = ''
        let mode = 3
      else
        let buf = buf.c
      endif
    elseif mode == 7  "escape in key string
      let mode = 6
    elseif mode == 8  "value string
      if c ==# '"'
        let mode = 10
      elseif c ==# '\'
        let mode = 9
      endif
    elseif mode == 9  "escape in value string
      let mode = 8
    elseif mode == 10 "end of value
      if c ==# ','
        if is_array
          let mode = 0
        else
          call remove(buf_list, len(buf_list) - 1)
          let mode = 1
        endif
      elseif c ==# '}'
        call remove(buf_list, len(buf_list) - 1)
        let is_obj = is_obj - 1
      elseif c ==# ']'
        let is_array = is_array - 1
      else
        let mode = -1
        break
      endif
    endif

    "echo c.', mode: '.mode
    let i = i + 1
  endwhile

  return [mode, buf_list]
endfunction
" ### parse JSON }}}

" ### Complete {{{
function! vison#resolver#complete(json_dict, query, base)
  let descriptors = vison#resolver#prop_descriptors(a:json_dict, a:query, a:base)
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

    let comp_item.menu = s:get_as_str(description.descriptor, 'type')
    if has_key(description.descriptor, 'description') 
      let comp_item.menu = comp_item.menu.', '.description.descriptor.description
    endif
    call add(result, comp_item)
  endfor
  return result
endfunction
" ### Complete }}}
