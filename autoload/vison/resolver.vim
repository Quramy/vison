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

" ### Parse JSON {{{
function! vison#resolver#get_query(lines)
  let joined = join(a:lines, '')
  let mode = 0
  let buf = ''
  let buf_list = []
  let structure_type_stack = []
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
        call add(structure_type_stack, 0)
        let mode = 1
      elseif c ==# '['
        call add(buf_list, {'key': '$array', 'enumerable': 1})
        call add(structure_type_stack, 1)
        let is_array = is_array + 1
      elseif c ==# 't' " is matched false
        if joined[(i):(i + 3)] ==# 'true'
          let i = i + 4
          let mode = 10
          continue
        else
          "echom 'invalid'
          let mode = 11
          break
        endif
      elseif c ==# 'f' " is matched false
        if joined[(i):(i + 4)] ==# 'false'
          let i = i + 5
          let mode = 10
          continue
        else
          "echom 'invalid'
          let mode = 11
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
      elseif is_array && c ==# ']'
        call remove(buf_list, len(buf_list) - 1)
        call remove(structure_type_stack, len(structure_type_stack) - 1)
        let is_array = is_array - 1
        let mode = 10
      else
        let mode = -1
        break
      endif
    elseif mode == 1
      if c ==# '}'
        "call remove(buf_list, len(buf_list) - 1)
        call remove(structure_type_stack, len(structure_type_stack) - 1)
        let is_obj = is_obj - 1
        let mode = 10
      elseif c ==# '"'
        let mode = 6
      else
        let mode = -1
        break
      endif
    elseif mode == 2 "number
      if c ==# ','
        if is_array
          let mode = 10
        else
          call remove(buf_list, len(buf_list) - 1)
          call remove(structure_type_stack, len(structure_type_stack) - 1)
          let mode = 1
        endif
      elseif c ==# '}'
        call remove(buf_list, len(buf_list) - 1)
        call remove(structure_type_stack, len(structure_type_stack) - 1)
        let is_obj = is_obj - 1
        let mode = 10
      elseif c ==# ']'
        let is_array = is_array - 1
        call remove(structure_type_stack, len(structure_type_stack) - 1)
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
        if structure_type_stack[len(structure_type_stack) - 1] == 0
          call remove(buf_list, len(buf_list) - 1)
          let mode = 1
        elseif structure_type_stack[len(structure_type_stack) - 1] == 1
          let mode = 0
        else
          let mode = -1
          break
        endif
      elseif c ==# '}'
        call remove(buf_list, len(buf_list) - 1)
        call remove(structure_type_stack, len(structure_type_stack) - 1)
        let is_obj = is_obj - 1
      elseif c ==# ']'
        call remove(buf_list, len(buf_list) - 1)
        call remove(structure_type_stack, len(structure_type_stack) - 1)
        let is_array = is_array - 1
      else
        let mode = -1
        break
      endif
    endif

    "echo c.', mode: '.mode.' st:'.string(structure_type_stack).' buf:'.string(buf_list)
    let i = i + 1
  endwhile

  return [mode, buf_list]
endfunction
" ### Parse JSON }}}

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
  "echo a:node a:query
  for prop in a:query

    if prop.key ==# 'definitions'
      if has_key(parent, 'definitions')
        let parent = {'properties': parent.definitions, 'type': 'object'}
        continue
      else
        return [0, {}]
      endif
    endif

    if s:has_match(parent, 'type', 'array') != -1
      if prop.key !=# '$array'
        return [0, {}]
      endif
      if !has_key(parent, 'items')
        return [0, {}]
      endif
      let [matched, parent] = vison#resolver#resolve_reference(parent.items, a:root_dict)
      if !matched
        return [matched, parent]
      endif
      continue
    endif

    if s:has_match(parent, 'type', 'object') != -1
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
  let [result, parent] = [[], {}]
  let [matched, node] = vison#resolver#get_node(a:json_dict, a:json_dict, a:query)
  if !matched || !has_key(node, 'properties')
    return [result, parent]
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

  return [result, node]
endfunction
" ### Get description }}}

" ### Complete {{{
let s:completer = {}

function! vison#resolver#make_typestr(descriptor, root_dict)
  if has_key(a:descriptor, 'enum')
    let tmp = []
    for item in a:descriptor.enum
      if ''.item is item " Item is string
        call add(tmp, '"'.item.'"')
      else               " Item is number
        call add(tmp, item)
      endif
    endfor
    return join(tmp, ' | ')
  elseif has_key(a:descriptor, 'type')
    try
      call strlen(a:descriptor.type)
      let tmp = [a:descriptor.type]
      if a:descriptor.type ==# 'string'
        let format = s:get_as_str(a:descriptor, 'format')
        let tmp[0] .= strlen(format) ? '(format: '.format.')' : ''
      elseif a:descriptor.type ==# 'array' && has_key(a:descriptor, 'items')
        let [matched, node] = vison#resolver#resolve_reference(a:descriptor.items, a:root_dict)
        if matched
          let tmp[0] = 'array<'.vison#resolver#make_typestr(node, a:root_dict).'>'
        else
          let tmp[0] = 'array'
        endif
      endif
    catch /^Vim\%((\a\+)\)\=:E730/
      let tmp = a:descriptor.type
    endtry
    return join(tmp, ' | ')
  else
    return 'unknown'
  endif
endfunction

function! s:completer.unknown(json_dict, type, query, base)
  return []
endfunction

function! s:completer.key(json_dict, type, query, base)
  let [descriptors, parent] = vison#resolver#prop_descriptors(a:json_dict, a:query, a:base)
  let result = []
  if stridx(&completeopt, 'menu') != -1
    if has_key(parent, 'required')
      let required = parent.required
    else
      let required = []
    endif
  endif
  for description in descriptors
    let comp_item = {} 
    if a:type == 1
      " User is going to write key string.
      let comp_item.word = '"'.description.name.'":'
    elseif a:type == 6
      " Uset is writing key string.
      let comp_item.word = description.name.'":'
    else
      let comp_item.word = description.name
    endif

    if stridx(&completeopt, 'menu') != -1

      let typestr = vison#resolver#make_typestr(description.descriptor, a:json_dict)
      let comp_item.menu = typestr
      if match(required, description.name) == -1
        let is_optional = 1
        let comp_item.menu = '?'.comp_item.menu
      else
        let is_optional = 0
      endif
      if stridx(&completeopt, 'preview') != -1
        let preview_info = []
        call add(preview_info, 'Type: '.typestr)
        if is_optional
          call add(preview_info, 'Optional: true')
        else
          call add(preview_info, 'Optional: false')
        endif
        if has_key(description.descriptor, 'description') 
          call add(preview_info, 'Description: '.description.descriptor.description)
        else 
          call add(preview_info, 'Description: No description in the schema')
        endif
        let comp_item.info = join(preview_info, "\n")
      endif
    endif
    call add(result, comp_item)
  endfor
  return result
endfunction

function! s:completer.value(json_dict, type, query, base)
  let result = []
  let [matched, descriptor] = vison#resolver#get_node(a:json_dict, a:json_dict, a:query)
  if !matched
    return result
  endif
  if has_key(descriptor, 'enum')
    for item in descriptor.enum
      if item is ''.item
        if a:type == 0
          call add(result, '"'.item.'"')
        elseif (a:type == 8 || a:type == 9) && stridx(item, a:base) == 0
          call add(result, item.'"')
        endif
      else
        if a:type == 0 || a:type == 2
          call add(result, item)
        endif
      endif
    endfor
    return result
  elseif has_key(descriptor, 'type')
    if descriptor.type ==# 'boolean' && (a:type == 0 || a:type == 11)
      return filter(['true', 'false'], "stridx(v:val, a:base) == 0")
    endif
  endif
endfunction

function! vison#resolver#complete(json_dict, type, query, base)
  let complete_type = 'unknown'
  if a:type == 1 || a:type == 6
    let complete_type = 'key'
  elseif a:type == 0 || a:type == 2 || a:type == 8 || a:type == 9 || a:type == 11
    let complete_type = 'value'
  endif
  return s:completer[complete_type](a:json_dict, a:type, a:query, a:base)
endfunction
" ### Complete }}}
