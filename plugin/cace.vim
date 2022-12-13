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
map <silent> <C-@> :call CACEUpdateDB()<CR>

" Use vimgrep for string search
cno vg call VimgrepInPrj("") <left><left><left>

" Auto load cscope db while opening a buffer
autocmd BufEnter /* call CACELoadDB()


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
	exe "cd " . CACEGetDBPath()
	echohl PreCondit | echo " Searching ..." | echohl None
	exe "silent vimgrep /" . a:target . CACEGenerateCMD("CACECMD_GREPTAR")
	exe "cd " . curpath
	let @/ = a:target
	exe "copen"
endfunction

function! VisualSearch(direction) range
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

function! CACELoadDB()
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

let g:caceUseC=1
let g:caceUseCpp=1
let g:caceUseMK=1
let g:caceUseDevTree=1
let g:caceInfoEveryTime = 1

let g:caceCTarget		= ["*.h", "*.c"]
let g:caceCppTarget		= ["*.hpp", "*.cpp", "*.cc"]
let g:caceMKTarget		= ["Makefile", "*.mk"]
let g:caceDevTreeTarget	= ["*.dts", "*.dtsi"]

let g:caceDBName = ['cscope.tags.lst', 'cscope.in.out', 'cscope.out', 'cscope.po.out', 'tags']

function! CACEGetTargetLists()
	let tlist = []
	if g:caceUseC == 1
		call add(tlist, g:caceCTarget	   )
	endif
	if g:caceUseCpp == 1
		call add(tlist, g:caceCppTarget	   )
	endif
	if g:caceUseMK == 1
		call add(tlist, g:caceMKTarget	   )
	endif
	if g:caceUseDevTree == 1
		call add(tlist, g:caceDevTreeTarget)
	endif
	return tlist
endfunction

function! CACEGenerateCMD(cmdtype)
	let tlists = CACEGetTargetLists()
	let cmdlist = []
	let cmd = ""
	if a:cmdtype == "CACECMD_DBLIST"
		call add(cmdlist, "find -name")
		let type = 0
		while type < len(tlists)
			let index = 0
			while index < len(tlists[type])
				let item = tlists[type][index]
				let isfirst = type + index
				if isfirst > 0
					call add(cmdlist, "-o -name")
				endif
				call add(cmdlist,'"' . item . '"')
				let index = index + 1
			endwhile
			let type = type + 1
		endwhile
		call add(cmdlist, "> cscope.tags.lst")
	elseif a:cmdtype == "CACECMD_GREPTAR"
		call add(cmdlist, "/j")
		let type = 0
		while type < len(tlists)
			let index = 0
			while index < len(tlists[type])
				let item = tlists[type][index]
				call add(cmdlist,'**/' . item)
				let index = index + 1
			endwhile
			let type = type + 1
		endwhile
	else
		echo "Unknown CMD tyep:"a:cmdtype
	endif
	let cmd = join(cmdlist)
	return cmd
endfunction

function! CACEGetDBPath()
	let db = findfile("cscope.out", getcwd() . ";")
	let dbpath = getcwd()
	if (!empty(db))
		if (db != "cscope.out")
			let dbpath = strpart(db, 0, match(db, "/cscope.out$"))
		endif
	endif
	return dbpath
endfunction

function! CACECleanDB()
	for item in g:caceDBName
		call delete(item)
	endfor
endfunction

function! CACEUpdateDB()
	let curcwd = getcwd()
	echohl PreCondit | echo " Updating tags & cscope, please wait ..." | echohl None
	exe "cd " . CACEGetDBPath()
	call CACECleanDB()
	call system(CACEGenerateCMD("CACECMD_DBLIST"))
	call system('ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst')
	call system('cscope -bkq -i cscope.tags.lst')
	silent exe "cs reset"
	call CACELoadDB()
	exe "cd " . curcwd
	echohl Identifier | echo " Updating finished" | echohl None
	if g:caceInfoEveryTime == 1
		echo "Working path:"getcwd()"\n DB info:\n"
		exe "cs show"
	endif
endfunction

set tags=tags;

