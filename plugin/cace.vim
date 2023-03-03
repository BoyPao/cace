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
" > Hightlight enhancemant for user defined symbols.

"==============================================================================
" Installation:
"==============================================================================
" > Install manually
"     git clone --depth=1 https://github.com/BoyPao/cace.git
"     cp cace.vim ~/.vim/plugin
"
" > Install by vim-plug (recommanded)
"     Plug 'BoyPao/cace'

"==============================================================================
" Commands:
"==============================================================================
" > Caceupdate
"     This command helps user to generate/update cscope, ctags and hightlight
"     database. It will search database from current working path upward.
"     If a database is found, it will update original database. If not, a new
"     database will be generated at current working path.
"     If user want to create database for a new project, it is suggested to
"     use this command at project root.
"
" > Caceclean
"     This command helps to find then delete the cscope, ctags and hightlight
"     database.
"
" > Cacegrep
"     This command executes vimgrep from cscope database directory for target
"     string. If cscope database locates at project root, this command will be
"     helpful when searching string under project in vim.
"
" > Cacefind
"     This command executes cscope find command, it wraps cscopequickfix open
"     operation. If cscopequickfix is on, result will be displayed in quickfix
"     window, and quickfix window will be open.
"     Example:
"             :Cacefind t hello
"         performs like:
"             :cs find t hello
"     It is recommand to map this command follow below methmod:
"         nnoremap <silent> zg :Cacefind g <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zc :Cacefind c <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zt :Cacefind t <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zs :Cacefind s <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zd :Cacefind d <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> ze :Cacefind e <C-R>=expand("<cword>")<CR><CR>
"         nnoremap <silent> zf :Cacefind f <C-R>=expand("<cfile>")<CR><CR>
"         nnoremap <silent> zi :Cacefind i <C-R>=expand("<cfile>")<CR><CR>
"
" > Cacequickfixtrigger
"     This command is a switch of cscopequickfix.
"

"==============================================================================
" Configuration:
"==============================================================================
" > g:caceInfoEveryTime
"     If g:caceInfoEveryTime equals to 1, cscope database loading information
"     will be display every time when Caceupdate executed. The default value
"     is 0.
"
" > g:caceUseC
"     It supports C language while executing Caceupdate. The default value is
"     1.
"
" > g:caceUseCpp
"     It supports Cpp language while executing Caceupdate. The default value is
"     1.
"
" > g:caceUseMK
"     It supports makefile language while executing Caceupdate. The default
"     value is 1.
"
" > g:caceUseDevTree
"     It supports arm device tree language while executing Caceupdate. The
"     default value is 1.
"
" > g:caceHightlightEnhance
"     It supports user defined symbol hightlight. The default value is 0.
"     Please check g:caceHLESupportedGroupMap for supported symbol information.
"     Note: If you turn on this feature, generating/updating database will take
"     more time. If you mind the time consumption, it's better to keep it as 0.

autocmd BufEnter /* call <SID>CACELoadDB()
set tags=tags;

if !exists(':Caceupdate')
	command! Caceupdate call <SID>CACEUpdateDB()
endif

if !exists(':Caceclean')
	command! Caceclean call <SID>CACECleanDB()
endif

if !exists(':Cacegrep')
	command! -nargs=1 Cacegrep call <SID>CACEGrepFunc(<q-args>)
endif

if !exists(':Cacefind')
	command! -nargs=+ Cacefind call <SID>CACEcscopeFind(<f-args>)
endif

if !exists(':Cacequickfixtrigger')
	command! Cacequickfixtrigger call <SID>CACECscopeQuickfixTrigger()
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
if !exists('g:caceHightlightEnhance')
    let g:caceHightlightEnhance=0
endif

let g:caceCTarget		= ["*.h", "*.c"]
let g:caceCppTarget		= ["*.hpp", "*.cpp", "*.cc"]
let g:caceMKTarget		= ["Makefile", "*.mk"]
let g:caceDevTreeTarget	= ["*.dts", "*.dtsi"]

" CACE-HLE(Hightlight Enhancement) supported tag type:
"	c - class
"	s - struct
"	d - macro
"	g - enum name
"	e - enum value
" HLE not supported tag type:
"	f
"	m
"	t
"	v
let g:caceHLESupportedGroupMap= { "c": "CACECTagsClass", "s": "CACECTagsStruct", "g": "CACECTagsEnumName", "e": "CACECTagsEnumValue", "d": "CACECTagsMacro"}

hi CACECTagsClass		guifg=#4ed99b guibg=NONE guisp=NONE gui=NONE ctermfg=79 ctermbg=NONE cterm=NONE
hi CACECTagsStruct      guifg=#4ed99b guibg=NONE guisp=NONE gui=NONE ctermfg=79 ctermbg=NONE cterm=NONE
hi CACECTagsEnumName	guifg=#4ed99b guibg=NONE guisp=NONE gui=NONE ctermfg=79 ctermbg=NONE cterm=NONE
hi CACECTagsEnumValue	guifg=#2ea303 guibg=NONE guisp=NONE gui=NONE ctermfg=121 ctermbg=NONE cterm=NONE
hi CACECTagsMacro		guifg=#ad77d4 guibg=NONE guisp=NONE gui=NONE ctermfg=140 ctermbg=NONE cterm=NONE

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
	exe "cd " . <SID>CACEGetDBPath("cscope.out")
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
	if g:caceHightlightEnhance == 1
		let hledb = findfile("cscope.tags.hle", getcwd() . ";")
		if (!empty(hledb))
			exe "source " . hledb
		endif
	endif
	return 0
endfunction

let g:caceDBDict = { "lst": "cscope.tags.lst", "hle": "cscope.tags.hle", "cscope": "cscope.in.out cscope.out cscope.po.out", "ctags": "tags"}

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

function! <SID>CACEGetDBPath(dbname)
	let db = findfile(a:dbname, getcwd() . ";")
	let dbpath = getcwd()
	if (!empty(db))
		if (db != a:dbname)
			let dbpath = strpart(db, 0, match(db, "/" . a:dbname . "$"))
		endif
	endif
	return dbpath
endfunction

function! <SID>CACECleanDB()
	let keys = keys(g:caceDBDict)
	for key in keys
		let dbs = split(g:caceDBDict[key])
		for db in dbs
			call delete(db)
		endfor
	endfor
	return 0
endfunction

function! <SID>CACEUpdateDB()
	let rt = 0
	let curcwd = getcwd()
	exe "cd " . <SID>CACEGetDBPath("cscope.out")
	call <SID>LOGI(" Updating tags & cscope, please wait ")
	let rt = <SID>CACECleanDB()
	if rt
		return
	endif
	call <SID>LOGI(" Updating tags & cscope, please wait .")
	call system(<SID>CACEGenerateCMD("CACECMD_DBLIST"))
	call <SID>LOGI(" Updating tags & cscope, please wait ..")
	call system('ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst')
	call <SID>LOGI(" Updating tags & cscope, please wait ...")
	call system('cscope -bkq -i cscope.tags.lst')
	call <SID>LOGI(" Updating tags & cscope, please wait ....")
	let rt = <SID>CACEUpdateHLE()
	if rt
		return
	endif
	call <SID>LOGI(" Updating tags & cscope, please wait .....")
	silent exe "cs reset"
	call <SID>CACELoadDB()
	if rt
		return
	endif
	call <SID>LOGI(" Updating tags & cscope, please wait ......")
	exe "cd " . curcwd
	call <SID>LOGS(" Updating finished")
	if g:caceInfoEveryTime == 1
		call <SID>LOG(" Working path:" . getcwd() . "\n DB info:\n")
		exe "cs show"
	endif
endfunction

function! <SID>CACEIsHLESuopprted(type)
	if strlen(a:type) > 1
		return 0
	endif
	let keys = keys(g:caceHLESupportedGroupMap)
	for key in keys
		if char2nr(a:type) == char2nr(key)
			return 1
		endif
	endfor
	return 0
endfunction

function! <SID>CACEHLEUpdateTrace(index, totle)
	call <SID>LOGI(" Updating HLEDB, please wait " . string(a:index * 100 / a:totle) . "%")
endfunction

" A maximal line words number which helps improve ctag parsing speed
if !exists('g:caceHLEWordsNumPerLine')
	let g:caceHLEWordsNumPerLine = 80
endif

let g:caceHLEUniquePatternDict = {}

function! <SID>CACEUpdateHLE()
	if g:caceHightlightEnhance == 0
		return 0
	endif
	let tag = findfile(g:caceDBDict["ctags"], ".;")
	if (empty(tag))
		call <SID>LOGE(" Update HLE failed. Cannot find: " . g:caceDBDict["ctags"])
		return 1
	endif
	let taglines = readfile(g:caceDBDict["ctags"])
	if empty(taglines)
		call <SID>LOGE(" Update HLE failed. Tag is empty: " . g:caceDBDict["ctags"])
		return 1
	endif

	let g:caceHLEUniquePatternDict = {}
	let ctagsdict = <SID>CACEParseCtag(taglines)
	let g:caceHLEUniquePatternDict = {}

	let wlines = []
	let keys = keys(ctagsdict)
	for key in keys
		if <SID>CACEIsHLESuopprted(strcharpart(key, 0, 1))
			call add(wlines, "syntax keyword " . g:caceHLESupportedGroupMap[strcharpart(key, 0, 1)] . " " . ctagsdict[key])
		endif
	endfor
	if len(wlines)
		call writefile(wlines, "cscope.tags.hle")
	endif

	let keys = keys(g:caceHLESupportedGroupMap)
	for key in keys
		exe "syntax clear " . g:caceHLESupportedGroupMap[key]
	endfor

	return 0
endfunction

let g:caceHLEInvalidKeywordDict = {"syn-arguments": "contains oneline fold display extend concealends conceal cchar contained containedin nextgroup transparent skipwhite skipnl skipempty"}

function! <SID>CACEHLEPatternInvalid(pattern)
	" Single char is not expected to be hightlighted
	" Vim hightlight spec: keyword length < 80. Please check: syn-keyword
	if strlen(a:pattern) < 2 || strlen(a:pattern) > 80
		return 1
	endif

	" keyword cannot be syn-argument. Please check: syn-arguments
	let keys = keys(g:caceHLEInvalidKeywordDict)
	for key in keys
		let invalidkeywordlist = split(g:caceHLEInvalidKeywordDict[key])
		for word in invalidkeywordlist
			if a:pattern == word
				return 1
			endif
		endfor
	endfor

	" Only hightlight a pattern onece
	if has_key(g:caceHLEUniquePatternDict, a:pattern)
		return 1
	else
		let g:caceHLEUniquePatternDict[a:pattern] = 1
	endif

	return 0
endfunction

function! <SID>CACEParseCtag(lines)
	let ctagsdict = {}
	let multitypemap = {}
	let linenum = len(a:lines)
	let linecnt = 0
	for line in a:lines
		let linecnt = linecnt + 1
		let tagtype = ""
		let tmp = split(line, '\"')
		if len(tmp) < 2
			continue
		elseif len(split(tmp[1])) < 1
			continue
		endif
		let tagtype = split(tmp[1])[0]

		if !<SID>CACEIsHLESuopprted(tagtype)
			continue
		endif

		let pattern = split(line)[0]
		if  len(split(pattern, "::")) > 1
			let pattern = split(pattern, "::")[len(split(pattern, "::")) - 1]
		endif
		if <SID>CACEHLEPatternInvalid(pattern)
			continue
		endif

		if !has_key(multitypemap, tagtype)
			let multitypemap[tagtype] = "0:0"
			let tagtype = tagtype . "0"
		else
			let typecnt = split(multitypemap[tagtype], ":")[0]
			let wordcnt = split(multitypemap[tagtype], ":")[1]
			if str2nr(wordcnt, 10) < g:caceHLEWordsNumPerLine
				let wordcnt = wordcnt + 1
			else
				let wordcnt = "1"
				let typecnt = typecnt + 1
			endif
			let multitypemap[tagtype] = typecnt . ":" . wordcnt
			let tagtype = tagtype . typecnt
		endif

		if !has_key(ctagsdict, tagtype)
			let ctagsdict[tagtype] = pattern
		else
			let dictori = ctagsdict[tagtype]
			let ctagsdict[tagtype] = dictori . " " . pattern
		endif

		if linecnt % 100 == 0
			call <SID>CACEHLEUpdateTrace(linecnt, linenum)
		endif
	endfor
	return ctagsdict
endfunction

function! <SID>LOG(str)
	echo a:str
endfunction
function! <SID>LOGI(str)
	redraw
	echohl Type | echo a:str | echohl None
endfunction
function! <SID>LOGW(str)
	echohl WarningMsg | echo a:str | echohl None
endfunction
function! <SID>LOGE(str)
	echohl ErrorMsg | echo a:str | echohl None
endfunction
function! <SID>LOGS(str)
	redraw
	echohl Comment | echo a:str | echohl None
endfunction

