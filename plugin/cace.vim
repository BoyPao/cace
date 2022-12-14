" License: GPL-3.0-or-later
"
" cace: ctags and cscope enhance.
" cace is a Vim plugin to help enhance the controls of ctags and cscope
"
" Copyright (c) 2021 Peng Hao <635945005@qq.com>

" Use vimgrep to search current word, better to use it with cscope in project root
nnoremap <silent> <leader>zt :call <SID>CACESearch(expand("<cword>"))<CR>
" use n/N/<leader>g to search current selection in visual mode, better to use it with cscope in project root
vnoremap <silent> <leader>zt y:call <SID>CACEVisualSearch('vg')<CR>
vnoremap <silent> n y:call <SID>CACEVisualSearch('f')<CR>
vnoremap <silent> N y:call <SID>CACEVisualSearch('b')<CR>
" On/off cscopequickfix
nmap <leader>cq :call <SID>CACECscopeQuickfixTrigger()<CR>
" Cscope key map
" find define
nnoremap <silent> zg :call <SID>CACEcscopeFind('g', expand("<cword>"))<CR>
" find who calls
nnoremap <silent> zc :call <SID>CACEcscopeFind('c', expand("<cword>"))<CR>
" find text
nnoremap <silent> zt :call <SID>CACEcscopeFind('t', expand("<cword>"))<CR>
" find symble
nnoremap <silent> zs :call <SID>CACEcscopeFind('s', expand("<cword>"))<CR>
" find who is called by selected
nnoremap <silent> zd :call <SID>CACEcscopeFind('d', expand("<cword>"))<CR>
" metch with egrep mode
nnoremap <silent> ze :call <SID>CACEcscopeFind('e', expand("<cword>"))<CR>
" find and open target file
nnoremap <silent> zf :call <SID>CACEcscopeFind('f', expand("<cfile>"))<CR>
" find who include target file
nnoremap <silent> zi :call <SID>CACEcscopeFind('i', expand("<cfile>"))<CR>
" Auto generate/update cscope DB
map <silent> <C-@> :call <SID>CACEUpdateDB()<CR>

" Use vimgrep for string search
cno vg call <SID>CACESearch("") <left><left><left>

" Auto load cscope db while opening a buffer
autocmd BufEnter /* call <SID>CACELoadDB()


set tags=tags;

if !exists(':CACEUpdate')
	command! CACEUpdate call <SID>CACEUpdateDB()
endif

if !exists(':CACEClean')
	command! CACEClean call <SID>CACECleanDB()
endif

if !exists('g:caceInfoEveryTime')
	let g:caceInfoEveryTime = 0
endif

if !exists('g:caceUseC')
	let g:caceUseC=1
endif
if !exists('g:caceUseCpp')
	let g:caceUseCpp=1
endif
if !exists('g:caceUseMK')
	let g:caceUseMK=1
endif
if !exists('g:caceUseDevTree')
	let g:caceUseDevTree=1
endif

function! <SID>CACECscopeQuickfixTrigger()
	if &cscopequickfix==""
		setlocal cscopequickfix=s-,c-,d-,i-,t-,e-
	else
		setlocal cscopequickfix=
	endif
	call <SID>LOG("cscopequickfix=" . &cscopequickfix)
endfunction

function! <SID>CACESearch(target)
	let curpath = getcwd()
	exe "cd " . <SID>CACEGetDBPath()
	call <SID>LOGI(" Searching ...")
	exe "silent vimgrep /" . a:target . <SID>CACEGenerateCMD("CACECMD_GREPTAR")
	call <SID>LOGS(" Searching Done")
	exe "cd " . curpath
	let @/ = a:target
	exe "copen"
endfunction

function! <SID>CACEVisualSearch(direction)
	let reg = @0
	if a:direction == 'vg'
		call <SID>CACESearch(reg)
	else
		if a:direction == 'b'
			exe "normal ?" . reg . "\n"
		elseif a:direction == 'f'
			exe "normal /" . reg . "\n"
		endif
		let @/ = reg
	endif
endfunction

function! <SID>CACEcscopeFind(mode, target)
	exe "cs find " . a:mode a:target
	if &cscopequickfix !=""
		exe "cw"
	endif
endfunction

function! <SID>CACELoadDB()
	let db = findfile("cscope.out", ".;")
	if (!empty(db))
		let path = strpart(db, 0, match(db, "/cscope.out$"))
		setlocal nocscopeverbose " suppress 'duplicate connection' error
		exe "cs add " . db . " " . path
		setlocal cscopeverbose " else add the database pointed to by environment variable
	elseif $CSCOPE_DB != ""
		cs add $CSCOPE_DB
	endif
endfunction

let g:caceCTarget		= ["*.h", "*.c"]
let g:caceCppTarget		= ["*.hpp", "*.cpp", "*.cc"]
let g:caceMKTarget		= ["Makefile", "*.mk"]
let g:caceDevTreeTarget	= ["*.dts", "*.dtsi"]

let g:caceDBName = ['cscope.tags.lst', 'cscope.in.out', 'cscope.out', 'cscope.po.out', 'tags']

function! <SID>CACEGetTargetLists()
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

function! <SID>CACEGenerateCMD(cmdtype)
	let tlists = <SID>CACEGetTargetLists()
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
		call <SID>LOGE("Unknown CMD tyep:" . a:cmdtype)
	endif
	let cmd = join(cmdlist)
	return cmd
endfunction

function! <SID>CACEGetDBPath()
	let db = findfile("cscope.out", getcwd() . ";")
	let dbpath = getcwd()
	if (!empty(db))
		if (db != "cscope.out")
			let dbpath = strpart(db, 0, match(db, "/cscope.out$"))
		endif
	endif
	return dbpath
endfunction

function! <SID>CACECleanDB()
	for item in g:caceDBName
		call delete(item)
	endfor
endfunction

function! <SID>CACEUpdateDB()
	let curcwd = getcwd()
	call <SID>LOGI(" Updating tags & cscope, please wait ...")
	exe "cd " . <SID>CACEGetDBPath()
	call <SID>CACECleanDB()
	call system(<SID>CACEGenerateCMD("CACECMD_DBLIST"))
	call system('ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst')
	call system('cscope -bkq -i cscope.tags.lst')
	silent exe "cs reset"
	call <SID>CACELoadDB()
	exe "cd " . curcwd
	call <SID>LOGS(" Updating finished")
	if g:caceInfoEveryTime == 1
		call <SID>LOG(" Working path:" . getcwd() . "\n DB info:\n")
		exe "cs show"
	endif
endfunction

function! <SID>LOG(str)
	echo a:str
endfunction
function! <SID>LOGI(str)
	echohl PreCondit | echo a:str | echohl None
endfunction
function! <SID>LOGW(str)
	echohl WarningMsg | echo a:str | echohl None
endfunction
function! <SID>LOGE(str)
	echohl ErrorMsg | echo a:str | echohl None
endfunction
function! <SID>LOGS(str)
	echohl Identifier | echo a:str | echohl None
endfunction
