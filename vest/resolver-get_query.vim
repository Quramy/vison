scriptencoding utf-8

let input_lines = []
Context vison#resolver#get_query
  It returns [type, keys] 
    Should vison#resolver#get_query(['']) == [0, []]
    Should vison#resolver#get_query(['""']) == [10, []]
    Should vison#resolver#get_query(['[]']) == [10, []]
    Should vison#resolver#get_query(['{}']) == [10, []]
    Should vison#resolver#get_query(['{"key":"value"}']) == [10, []]
    Should vison#resolver#get_query(['"{,\":}"']) == [10, []]
    Should vison#resolver#get_query(['true']) == [10, []]
    Should vison#resolver#get_query(['false']) == [10, []]
    Should vison#resolver#get_query(['null']) == [10, []]
    Should vison#resolver#get_query(['10']) == [2, []]
    Should vison#resolver#get_query(['-1']) == [2, []]
    Should vison#resolver#get_query(['3.0']) == [2, []]
    Should vison#resolver#get_query(['3.0e10']) == [2, []]
  End
  It returns -1 of type with invalid value
    Should vison#resolver#get_query(['tr']) == [11, []]
    Should vison#resolver#get_query(['tRUE']) == [11, []]
    Should vison#resolver#get_query(['TRUE']) == [-1, []]
    Should vison#resolver#get_query(['False']) == [-1, []]
    Should vison#resolver#get_query(['fAlse']) == [11, []]
  End
  It returns keys of incomplete JSON input
    Should vison#resolver#get_query(['{']) == [1, []]
    Should vison#resolver#get_query(['{"']) == [6, []]
    Should vison#resolver#get_query(['{"hoge']) == [6, []]
    Should vison#resolver#get_query(['{"hoge"']) == [3, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['{"hoge":']) == [0, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['{"hoge": "']) == [8, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['{"hoge": "\']) == [9, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['{"hoge": {']) == [1, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['{"hoge": {"']) == [6, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['{"hoge": {"foo": [']) == [0, [{'key': 'hoge', 'enumerable': 0}, {'key': 'foo', 'enumerable': 0}, {'key': '$array', 'enumerable': 1}]]
    Should vison#resolver#get_query(['{"hoge": {"foo": ["bar"]}']) == [10, [{'key': 'hoge', 'enumerable': 0}]]
    Should vison#resolver#get_query(['[']) == [0, [{'key': '$array', 'enumerable': 1}]]
  End
  It returns keys with complex inputs
    let input_lines = [
          \ '{',
          \ '  "name": "vison",',
          \ '  "version": "0.0.1",',
          \ '  "directories": [{',
          \ '    "name": "main"',
          \ '  }, {',
          \ '    "name":'
          \ ]
    "echo vison#resolver#get_query(input_lines) 
    Should vison#resolver#get_query(input_lines) == [0, [{'key': 'directories', 'enumerable': 0}, {'key': '$array', 'enumerable': 1}, {'key': 'name', 'enumerable': 0}]]
  End
End
