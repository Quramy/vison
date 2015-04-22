
if has('vim_starting')
  set nocompatible
  let s:basedir = expand('<sfile>:p:h').'/../'

  execute('set runtimepath+='.s:basedir)
  execute('set runtimepath+='.s:basedir.'neobundle.vim')
  call neobundle#begin(expand(s:basedir.'bundle'))

  NeoBundle 'Shougo/unite.vim'
  NeoBundle 'Shougo/vesting'

  " If you need other plugins for your test, append dependencies.
  " e.g. 
  " NeoBundle 'Shougo/vimproc.vim', {
  "       \ 'build' : {
  "       \     'windows' : 'tools\\update-dll-mingw',
  "       \     'cygwin' : 'make -f make_cygwin.mak',
  "       \     'mac' : 'make -f make_mac.mak',
  "       \     'linux' : 'make',
  "       \     'unix' : 'gmake',
  "       \    },
  "       \ }

  call neobundle#end()
  silent NeoBundleInstall
endif

