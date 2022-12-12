" License: GPL-3.0-or-later
"
" cace: ctags and cscope enhance.
" cace is a Vim plugin to help enhance the controls of ctags and cscope
"
" Copyright (c) 2021 Peng Hao <635945005@qq.com>

" Use vimgrep to search current word, better to use it with cscope in project root
nnoremap <silent> <leader>zt :call VimgrepInPrj(expand("<cword>"))<CR>
" use n/N/<leader>g to search current selection in visual mode, better to use it with cscope in project root
vnoremap <silent> <leader>zt y:call VisualSearch('vg')<CR>
vnoremap <silent> n y:call VisualSearch('f')<CR>
vnoremap <silent> N y:call VisualSearch('b')<CR>
" On/off cscopequickfix
nmap <leader>cq :call SwitchCscopeQuickfix()<CR>
" Cscope key map
" find define
nnoremap <silent> zg :call CscopeSearch('g', expand("<cword>"))<CR>
" find who calls
nnoremap <silent> zc :call CscopeSearch('c', expand("<cword>"))<CR>
" find text
nnoremap <silent> zt :call CscopeSearch('t', expand("<cword>"))<CR>
" find symble
nnoremap <silent> zs :call CscopeSearch('s', expand("<cword>"))<CR>
" find who is called by selected
nnoremap <silent> zd :call CscopeSearch('d', expand("<cword>"))<CR>
" metch with egrep mode
nnoremap <silent> ze :call CscopeSearch('e', expand("<cword>"))<CR>
" find and open target file
nnoremap <silent> zf :call CscopeSearch('f', expand("<cfile>"))<CR>
" find who include target file
nnoremap <silent> zi :call CscopeSearch('i', expand("<cfile>"))<CR>
" Auto generate/update cscope DB
map <silent> <C-@> :call UpdateCscopeDB()<CR>

" Use vimgrep for string search
cno vg call VimgrepInPrj("") <left><left><left>

" Auto load cscope db while opening a buffer
autocmd BufEnter /* call LoadCscope()


let g:cqswitch="OFF"
function! SwitchCscopeQuickfix()
	if &cscopequickfix==""
		set cscopequickfix=s-,c-,d-,i-,t-,e-
		let g:cqswitch="ON"
	else
		set cscopequickfix=
		let g:cqswitch="OFF"
	endif
	echo "cscopequickfix="&cscopequickfix
endfunction

function! VimgrepInPrj(target)
	let curpath = getcwd()
	exe "cd" . GetCscopeDBPath()
	echohl PreCondit | echo " Searching ..." | echohl None
	exe "silent vimgrep /" . a:target . "/j **/*.c **/*.cpp **/*.h **/*.hpp **/*.dtsi **/*.dts"
	exe "cd" . curpath
	let @/ = a:target
	exe "copen"
endfunction

function VisualSearch(direction) range
	let reg = @0
	if a:direction == 'vg'
		call VimgrepInPrj(reg)
	else
		if a:direction == 'b'
			exe "normal ?" . reg . "\n"
		elseif a:direction == 'f'
			exe "normal /" . reg . "\n"
		endif
		let @/ = reg
	endif
endfunction

function! CscopeSearch(mode, target)
	exe "cs find " . a:mode a:target
	if &cscopequickfix !=""
		exe "cw"
	endif
endfunction

function! LoadCscope()
	let db = findfile("cscope.out", ".;")
	if (!empty(db))
		let path = strpart(db, 0, match(db, "/cscope.out$"))
		set nocscopeverbose " suppress 'duplicate connection' error
		exe "cs add " . db . " " . path
		set cscopeverbose " else add the database pointed to by environment variable
	elseif $CSCOPE_DB != ""
		cs add $CSCOPE_DB
	endif
endfunction

" Auto update/generate ctags and cscope
function! GetCscopeDBPath()
	let db = findfile("cscope.out", ".;")
	let dbpath = getcwd()
	if (!empty(db))
		if (db != "cscope.out")
			let dbpath = strpart(db, 0, match(db, "/cscope.out$"))
		endif
	endif
	return dbpath
endfunction

function! UpdateCscopeDB()
	let curcwd = getcwd()
	echohl PreCondit | echo " Updating tags & cscope, please wait ..." | echohl None
	exe "cd" . GetCscopeDBPath()
	call delete('cscope.tags.lst')
	call delete('cscope.in.out')
	call delete('cscope.out')
	call delete('cscope.po.out')
	call delete('tags')
	let cmd='find -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.dtsi" -o -name "*.dts" -o -name "Makefile" -o -name "*.mk" > cscope.tags.lst'
	call system(cmd)
	let cmd='ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst'
	call system(cmd)
	let cmd='cscope -bkq -i cscope.tags.lst'
	call system(cmd)
	silent exe "cs reset"
	call LoadCscope()
	exe "cd" . curcwd
	echohl Identifier | echo " Updating finished" | echohl None
	echo "Working path:"getcwd()"\nDB info:\n"
	exe "cs show"
endfunction

" ctags config
set tags=tags;

