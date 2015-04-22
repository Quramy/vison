"============================================================================
" FILE: autoload/vison/resolver.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('vison')

function! vison#resolver#resolve(json_dict, query)

  " Check schema.
  if !has_key(json_dict, 'properties')
    return
  endif

  let prop_def = json_dict.properties
  for prop in query
    if has_key(prop_def, prop.key)
    else
      break
    endif
  endfor
endfunction

function! vison#resolver#prop_descriptors(json_dict, query, base)
  " Check schema.
  if !has_key(a:json_dict, 'properties')
    return
  endif

  let prop_def = a:json_dict
  for prop in a:query
    if has_key(prop_def, prop.key)
    else
      break
    endif
  endfor

  let props = keys(prop_def.properties)
  let result = []
  for prop_name in props
    if a:base !=# '' && stridx(prop_name, a:base) == -1
      continue
    endif
    call add(result, {'name': prop_name, 'descriptor': prop_def.properties[prop_name]})
  endfor

  return result
endfunction

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
          let buf_list[len(buf_list) - 1].enumerable = 1
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
