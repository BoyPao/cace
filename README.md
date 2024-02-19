# CACE
cace: ctags and cscope enhance.
cace is a Vim plugin to help enhance the controls of ctags and cscope

License: GPL-3.0-or-later
Copyright (c) 2021 Peng Hao <635945005@qq.com>

# Features
- Autoload cscope & ctags database
- Provide command to update cscope & ctags database.
- Provide command to search string.
- Highlight enhancement for user defined symbols.
- Provide background process for database updating by async methmod.

# Installation
- Install manually
```
git clone --depth=1 https://github.com/BoyPao/cace.git
cp cace.vim ~/.vim/plugin
```
- Install by vim-plug (recommanded)
```
Plug 'BoyPao/cace'
```

# Command
- Caceupdate

This command helps user to generate/update cscope, ctags and highlight database.
It will search database from current working path upward.
If a database is found, it will update original database.
If not, a new database will be generated at current working path.
If user want to create database for a new project, it is suggested to use this command at project root.

- Caceupdatehle

This command helps updating only highlight database.

- Caceclean

This command helps to delete the cscope, ctags and highlight database.
To prevent deleting database which loacted in uper folder, this command only performs in current working path.

- Cacegrep

This command executes vimgrep from cscope database directory for target string.
If cscope database locates at project root, this command will be helpful when searching string under project in vim.

- Cacefind

This command executes cscope find command, it wraps cscopequickfix open operation.
If cscopequickfix is on, result will be displayed in quickfix window, and quickfix window will be open.
Example:
```
:Cacefind t hello
```
performs like:
```
:cs find t hello
```
It is recommand to map this command follow below methmod:
```
nnoremap <silent> zg :Cacefind g <C-R>=expand("<cword>")<CR><CR>
nnoremap <silent> zc :Cacefind c <C-R>=expand("<cword>")<CR><CR>
nnoremap <silent> zt :Cacefind t <C-R>=expand("<cword>")<CR><CR>
nnoremap <silent> zs :Cacefind s <C-R>=expand("<cword>")<CR><CR>
nnoremap <silent> zd :Cacefind d <C-R>=expand("<cword>")<CR><CR>
nnoremap <silent> ze :Cacefind e <C-R>=expand("<cword>")<CR><CR>
nnoremap <silent> zf :Cacefind f <C-R>=expand("<cfile>")<CR><CR>
nnoremap <silent> zi :Cacefind i <C-R>=expand("<cfile>")<CR><CR>
```

- Cacequickfixtrigger

This command is a switch of cscopequickfix.

# Configuration
- g:caceHighlightEnhance

If the value is 1, it will performs a extral highlight for user defined symbols.
The default value is 0. Please check s:caceHLESupportedGroupMap for supported symbol informations.
*Note:* If you turn on this feature, generating/updating database will take more time. If you mind the time consumption, it's better to keep it as 0.
