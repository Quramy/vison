scriptencoding utf-8

let s:V = vital#of('vison')
let s:Filepath = s:V.import('System.Filepath')

Context vison#resolver#prop_descriptors
  It returns a list of root property descriptors with empty query.
    let file_loader_dict = vison#misc#load(s:Filepath.join(vison#base_dir(), 'vest/schemas/simple.json'))
    let [descriptors, parent] = vison#resolver#prop_descriptors(file_loader_dict, [], '')
    Should descriptors == [{'name': 'stringProp', 'descriptor': {'type': 'string', 'description': 'A string prop'}}]
    Should parent is file_loader_dict

    let [descriptors, parent] = vison#resolver#prop_descriptors(file_loader_dict, [], '')
    Should descriptors == [{'name': 'stringProp', 'descriptor': {'type': 'string', 'description': 'A string prop'}}]

    let file_loader_dict = vison#misc#load(s:Filepath.join(vison#base_dir(), 'vest/schemas/reference.json'))
    let [descriptors, parent] = vison#resolver#prop_descriptors(file_loader_dict, [], '') 
    Should descriptors == [{'name': 'alias', 'descriptor': {'type': 'string', 'description': 'A string prop'}}]
    unlet file_loader_dict descriptors parent
  End

  It returns descriptors with a query which includes array notation.
    let file_loader_dict = vison#misc#load(s:Filepath.join(vison#base_dir(), 'vest/schemas/array01.json'))
    let [descriptors, parent] = vison#resolver#prop_descriptors(file_loader_dict, [{'key': '$array', 'enumerable': 1}], '')
    Should descriptors == [{'name': 'stringProp', 'descriptor': {'type': 'string'}}]
    Should parent is file_loader_dict.items
    unlet file_loader_dict descriptors parent
  End
End

