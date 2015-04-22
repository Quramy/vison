# vison [![Build Status](https://travis-ci.org/Quramy/vison.svg?branch=master)](https://travis-ci.org/Quramy/vison)

Vison is a Vim plugin to help writing `*.json` file with JSON Schema.

Do you think "What kind keys does this JSON need" ?

Can you remember structure of the JSON file ?

And do you open your browser and search "package.json" or "bower.json" ?

Always I do. And I feel disgusted that I come and go between my browser and Vim.

So, I make this plugin.

Vison provides:

* completion keys from schema.
* manegement JSON schema files.


## How to install

If you use NeoBundle for Vim plugins management, append the following to your `.vimrc`:

```vim
NeoBundle 'Quramy/vison'
```

And exec `:NeoBundleInstall`.

## Getting started
**T.B.D.**

## Usage

### Switch schema
Using omni-completion, you can call the `:VisonSwitch` command.
This command requires an argument, which is schema name.

For example, writing package.json call `:VisonSwitch package.json`

Also you can write the following to `.vimrc` for auto switching:

```vim
autocmd BufRead,BufNewFile package.json VisonSwitch package.json
```

### Register schema file

First, open some JSON schema file in Vim.
Second, exec `:VisonRegistSchema`.

So, the schema file is registered into the vison.
By the default, the schema file is copied into the `~/.cache/vison/default` directory.

This command regards the basename of the current buffer as the schema name.
If the basename is `package.json` then the schema name is also `package.json`.

To set schema name explicitly, call this command with the argument.

For example `:VisonRegistSchema npm-package`.

## Customize
*T.B.D.*
