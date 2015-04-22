scriptencoding utf-8

let s:V = vital#of('vison')
let s:Filepath = s:V.import('System.Filepath')

Context vison#resolver#prop_descriptors
  It returns propertis
    let file_loader_dict = vison#loader#file_loader(s:Filepath.join(vison#base_dir(), 'vest/schemas/package.json'))
    let prop_descriptors = vison#resolver#prop_descriptors(file_loader_dict, [], '')
  End
End

