scriptencoding utf-8

Context vison#resolver#get_node
  It returns [matched, node] with query. The node is a partial dictionay in the dictionay of input.
    let root_dict = {'type': 'object', 'properties': {'a' : {'type': 'string'}}}
    Should vison#resolver#get_node(root_dict, root_dict, [{'key': 'a', 'enumerable': 0}]) == [1, {'type': 'string'}]

    let root_dict = {'type': 'array', 'items': {'type': 'object', 'properties': {'a': {'type': 'string'}}}}
    Should vison#resolver#get_node(root_dict, root_dict, [{'key': '$array', 'enumerable': 1}, {'key': 'a', 'enumerable': 0}]) == [1, {'type': 'string'}]
    unlet root_dict
  End

  It returns resolved node with '$ref'.
    let root_dict = {'definitions': {'b': {'type': 'string'}}, 'type': 'object', 'properties': {'alias' : {'$ref': '#/definitions/b'}}}
    Should vison#resolver#get_node(root_dict, root_dict, [{'key': 'alias', 'enumerable': 0}]) == [1, {'type': 'string'}]

    let root_dict = {'type': 'array', 'items': {'$ref': '#/definitions/b'},'definitions': {'b': {'type': 'string'}}}
    Should vison#resolver#get_node(root_dict, root_dict, [{'key': '$array', 'enumerable': 1}]) == [1, {'type': 'string'}]
    unlet root_dict
  End

End
