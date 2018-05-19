from .base import Base


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)
        self.vim = vim
        self.name = 'vison'
        self.kind = 'command'

    def gather_candidates(self, context):
        bufname = self.vim.current.buffer.name
        catalog = self.vim.call('vison#store#get_catalog')
        vison = list(map(lambda symbol: {
            'word': symbol,
            'action__command': 'Vison {0}'.format(symbol)
        }, catalog['$short']))

        return sorted(vison, key=lambda value: value['word'])
