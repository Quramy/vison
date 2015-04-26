scriptencoding utf-8

let s:V = vital#of('vison')
let s:Filepath = s:V.import('System.Filepath')

Context vison#resolver#prop_descriptors
  It returns a list of root property descriptors with empty query.
    let file_loader_dict = vison#misc#load(s:Filepath.join(vison#base_dir(), 'vest/schemas/simple.json'))
    Should vison#resolver#prop_descriptors(file_loader_dict, [], '')
          \ == [{'name': 'stringProp', 'descriptor': {'type': 'string', 'description': 'A string prop'}}]

    let file_loader_dict = vison#misc#load(s:Filepath.join(vison#base_dir(), 'vest/schemas/reference.json'))
    Should vison#resolver#prop_descriptors(file_loader_dict, [], '') 
          \ == [{'name': 'alias', 'descriptor': {'type': 'string', 'description': 'A string prop'}}]
  End

  It returns descriptors with a query which includes array notation.
    let file_loader_dict = vison#misc#load(s:Filepath.join(vison#base_dir(), 'vest/schemas/array01.json'))
    Should vison#resolver#prop_descriptors(file_loader_dict, [{'key': 'arrayProp', 'enumerable': 1}], '')
          \ ==[{'name': 'stringProp', 'descriptor': {'type': 'string'}}]
  End
End

