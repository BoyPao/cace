" License: GPL-3.0-or-later
"
" cace: ctags and cscope enhance.
" cace is a Vim plugin to help enhance the controls of ctags and cscope
"
" Copyright (c) 2021 Peng Hao <635945005@qq.com>

"==============================================================================
" Features:
"==============================================================================
" > Autoload cscope & ctags database
" > Provide command to update cscope & ctags database.
" > Provide command to search string.

"==============================================================================
" Installation:
"==============================================================================
" > Instal manually
"     1. git clone https://github.com/BoyPao/cace
"     2. cp cace.vim ~/.vim/plugin
"
" > Instal by vim-plug (recommanded)
"     Plug 'BoyPao/cace'

"==============================================================================
" Commands:
"==============================================================================
" > CACEUpdate
"     This command helps user to generate/update cscope and ctags database. It
"     will search database from current working path upward. If a database is
"     found, it will update original database. If not, a new database will be
"     generated at current working path.
"     If user want to create database for a new project, it is suggested to
"     use this command at project root.
"
" > CACEClean
"     This command helps to find then delete the cscope and ctags database.
"
" > CACEGrep
"     This command executes vimgrep from cscope database directory for target
"     string. If cscope database locates at project root, this command will be
"     helpful when searching string under project in vim.
"
" > CACEUFind
"     This command executes cscope find command, it wraps cscopequickfix open
"     operation. if cscopequickfix is on, result will be displayed in quickfix
"     window, and quickfix window will be open.
"     Example:
"             :CACEFind t hello
"         performs like:
"             :cs find t hello
"     It is recommand to map this command follow below methmod:
"         nnoremap <silent> zg :CACEFind g <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zc :CACEFind c <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zt :CACEFind t <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zs :CACEFind s <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zd :CACEFind d <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> ze :CACEFind e <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zf :CACEFind f <C-R>=expand("<cfile>")<CR><CR>
"         nnoremap <silent> zi :CACEFind i <C-R>=expand("<cfile>")<CR><CR>
"
" > CACEQuickfixTrigger
"     This command is a switch of cscopequickfix.
"

"==============================================================================
" Configuration:
"==============================================================================
" > g:caceInfoEveryTime
"     If g:caceInfoEveryTime equals to 1, cscope database loading information
"     will be display every time when CACEUpdate executed. The default value
"     is 0.
"
" > g:caceUseC
"     It supports C language while executing CACEUpdate. The default value is
"     1.
"
" > g:caceUseCpp
"     It supports Cpp language while executing CACEUpdate. The default value is
"     1.
"
" > g:caceUseMK
"     It supports makefile language while executing CACEUpdate. The default
"     value is 1.
"
" > g:caceUseDevTree
"     It supports arm device tree language while executing CACEUpdate. The
"     default value is 1.

autocmd BufEnter /* call <SID>CACELoadDB()
set tags=tags;

if !exists(':CACEUpdate')
	command! CACEUpdate call <SID>CACEUpdateDB()
endif

if !exists(':CACEClean')
	command! CACEClean call <SID>CACECleanDB()
endif

if !exists(':CACEGrep')
	command! -nargs=1 CACEGrep call <SID>CACEGrepFunc(<q-args>)
endif

if !exists(':CACEFind')
	command! -nargs=+ CACEFind call <SID>CACEcscopeFind(<f-args>)
endif

if !exists(':CACEQuickfixTrigger')
	command! CACEQuickfixTrigger call <SID>CACECscopeQuickfixTrigger()
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

let g:caceCTarget		= ["*.h", "*.c"]
let g:caceCppTarget		= ["*.hpp", "*.cpp", "*.cc"]
let g:caceMKTarget		= ["Makefile", "*.mk"]
let g:caceDevTreeTarget	= ["*.dts", "*.dtsi"]

function! <SID>CACECscopeQuickfixTrigger()
	if &cscopequickfix==""
		setlocal cscopequickfix=s-,c-,d-,i-,t-,e-
	else
		setlocal cscopequickfix=
	endif
	call <SID>LOG("cscopequickfix=" . &cscopequickfix)
endfunction

function! <SID>CACEGrepFunc(target)
	let curpath = getcwd()
	exe "cd " . <SID>CACEGetDBPath()
	call <SID>LOGI(" Searching ...")
	exe "silent vimgrep /" . a:target . <SID>CACEGenerateCMD("CACECMD_GREPTAR")
	redraw
	call <SID>LOGI(" ")
	exe "cd " . curpath
	let @/ = a:target
	exe "copen"
endfunction

function! <SID>CACEcscopeFind(mode, target)
	let modevalid = 0
	if a:mode == 'g'
		let modevalid = 1
	endif
	if a:mode == 'c'
		let modevalid = 1
	endif
	if a:mode == 't'
		let modevalid = 1
	endif
	if a:mode == 's'
		let modevalid = 1
	endif
	if a:mode == 'd'
		let modevalid = 1
	endif
	if a:mode == 'e'
		let modevalid = 1
	endif
	if a:mode == 'f'
		let modevalid = 1
	endif
	if a:mode == 'i'
		let modevalid = 1
	endif
	if modevalid == 0
		call <SID>LOGE("Invalid mode: " . a:mode)
	else
		exe "cs find " . a:mode a:target
		if &cscopequickfix !=""
			exe "cw"
		endif
	endif
endfunction

function! <SID>CACELoadDB()
	let db = findfile("cscope.out", ".;")
	if (!empty(db))
		let path = strpart(db, 0, match(db, "/cscope.out$"))
		setlocal nocscopeverbose
		exe "cs add " . db . " " . path
		setlocal cscopeverbose
	elseif $CSCOPE_DB != ""
		exe "cs add " . $CSCOPE_DB
	endif
endfunction

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
	exe "cd " . <SID>CACEGetDBPath()
	call <SID>LOGI(" Updating tags & cscope, please wait ")
	call <SID>CACECleanDB()
	call <SID>LOGI(" Updating tags & cscope, please wait .")
	call system(<SID>CACEGenerateCMD("CACECMD_DBLIST"))
	call <SID>LOGI(" Updating tags & cscope, please wait ..")
	call system('ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst')
	call <SID>LOGI(" Updating tags & cscope, please wait ...")
	call system('cscope -bkq -i cscope.tags.lst')
	call <SID>LOGI(" Updating tags & cscope, please wait ....")
	silent exe "cs reset"
	call <SID>CACELoadDB()
	call <SID>LOGI(" Updating tags & cscope, please wait .....")
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
	redraw
	echohl PreCondit | echo a:str | echohl None
endfunction
function! <SID>LOGW(str)
	echohl WarningMsg | echo a:str | echohl None
endfunction
function! <SID>LOGE(str)
	echohl ErrorMsg | echo a:str | echohl None
endfunction
function! <SID>LOGS(str)
	redraw
	echohl Identifier | echo a:str | echohl None
endfunction
