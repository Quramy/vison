scriptencoding utf-8

let s:V = vital#of('vison')
let s:Filepath = s:V.import('System.Filepath')

Context vison#loader#file_loader
  It returns a dictionay if input file exists.
    let file_loader_dict = vison#loader#file_loader(s:Filepath.join(vison#base_dir(), 'vest/schemas/package.json'))
    echo file_loader_dict
  End
End
