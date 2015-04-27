scriptencoding utf-8

let s:root_dict = {'type': 'object', 'properties': {'a' : {'type': 'string'}}}

" => [1, {...}]
echo vison#resolver#get_node(s:root_dict, s:root_dict, [{'key': 'a', 'enumerable': 0}])

let s:root_dict = {'definitions': {'b': {'type': 'object', 'properties': {'a': {'type': 'string'}}}}, 'type': 'object', 'properties': {'alias' : {'$ref': '#/definitions/b'}}}
echo vison#resolver#get_node(s:root_dict, s:root_dict, [{'key': 'alias', 'enumerable': 0}])

let s:root_dict = {'type': 'array', 'items': {'type': 'object', 'properties': {'a': {'type': 'string'}}}}
echo vison#resolver#get_node(s:root_dict, s:root_dict, [{'key': '$array', 'enumerable': 1}, {'key': 'a', 'enumerable': 0}])
