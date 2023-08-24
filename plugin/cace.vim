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
" > Highlight enhancemant for user defined symbols.
" > Provide background process for database updating by async methmod.

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
"     This command helps user to generate/update cscope, ctags and highlight
"     database. It will search database from current working path upward.
"     If a database is found, it will update original database. If not, a new
"     database will be generated at current working path.
"     If user want to create database for a new project, it is suggested to
"     use this command at project root.
"
" > Caceupdatehle
"     This command helps updating only highlight database.
"
" > Caceclean
"     This command helps to delete the cscope, ctags and highlight database.
"     To prevent deleting database which loacted in uper folder, this command
"     only performs in current working path.
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
" > g:caceHighlightEnhance
"     If the value is 1, it will performs a extral highlight for user defined
"     symbols. The default value is 0. Please check s:caceHLESupportedGroupMap
"     for supported symbol informations.
"     Note: If you turn on this feature, generating/updating database will take
"     more time. If you mind the time consumption, it's better to keep it as 0.

autocmd BufEnter /* call s:CACELoadDB()
autocmd VimLeavePre /* call s:CACEFlushJobs()
autocmd CursorMoved /* call s:CACECursorMoved()

set tags=tags;

if !exists(':Caceupdate')
	command! Caceupdate call s:CACEUpdateDB()
endif

if !exists(':Caceupdatehle')
	command! Caceupdatehle call s:CACEUpdateHLE()
endif

if !exists(':Caceclean')
	command! Caceclean call s:CACECleanDB('all')
endif

if !exists(':Cacegrep')
	command! -nargs=1 Cacegrep call s:CACEGrepFunc(<q-args>)
endif

if !exists(':Cacefind')
	command! -nargs=+ Cacefind call s:CACEcscopeFind(<f-args>)
endif

if !exists(':Cacequickfixtrigger')
	command! Cacequickfixtrigger call s:CACECscopeQuickfixTrigger()
endif

if !exists('g:caceHighlightEnhance')
	let g:caceHighlightEnhance = 0
endif

if version >= 800
	let s:caceAsyncProcess = 1
else
	let s:caceAsyncProcess = 0
endif

let s:caceCWD = ''

let s:caceJobsDict = {}

let s:cacePendingSInfoQueue = []

let s:cacePendingEInfoQueue = []

let s:caceFinding = 0

let s:caceRetryCnt = 3

let s:caceSkipCscopeReset = 0

let s:caceMsgSymbolDict = {
			\ 'start' : 'CACE-S',
			\ 'end' : 'CACE-E'
			\ }

let s:caceMsgErrorSymbols = [
			\ 'Error',
			\ 'ERROR'
			\ ]

let s:caceJobCmdId = {
			\ 'lst' : 'CACECMD_LST',
			\ 'cscope' : 'CACECMD_CSCOPE',
			\ 'ctags' : 'CACECMD_CTAGS',
			\ 'hle' : 'CACECMD_HLE'
			\ }

let s:caceTargetFileTypeMap = {
			\ 'c' : '.h .c',
			\ 'cpp' : '.hpp .cpp .cc',
			\ 'mk' : 'Makefile Kconfig .mk',
			\ 'dts' : '.dtsi .dts'
			\ }

let s:caceDBDict = {
			\ 'lst' : 'cscope.tags.lst',
			\ 'cscope' : 'cscope.in.out cscope.out cscope.po.out',
			\ 'ctags' : 'tags',
			\ 'hle' : 'cscope.tags.hle'
			\ }

let s:caceCscopeFindModeDict = {
			\ 'g' : 1,
			\ 'c' : 1,
			\ 't' : 1,
			\ 's' : 1,
			\ 'd' : 1,
			\ 'e' : 1,
			\ 'f' : 1,
			\ 'i' : 1
			\ }

" CACE-HLE(Highlight Enhancement) supported tag type:
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
let s:caceHLESupportedGroupMap = {
			\ 'c' : 'CACECTagsClass',
			\ 's' : 'CACECTagsStruct',
			\ 'g' : 'CACECTagsEnumName',
			\ 'e' : 'CACECTagsEnumValue',
			\ 'd' : 'CACECTagsMacro'
			\ }

let s:caceHLEInvalidKeywordDict = {
			\ 'syn-arguments' : 'contains oneline fold display extend concealends conceal cchar contained containedin nextgroup transparent skipwhite skipnl skipempty'
			\ }

" A maximal line words number which helps improve ctag parsing speed
let s:caceHLEWordsNumPerLine = 80

let s:caceHLEUniquePatternDict = {}

hi CACECTagsClass		guifg=#4ed99b guibg=NONE guisp=NONE gui=NONE ctermfg=79 ctermbg=NONE cterm=NONE
hi CACECTagsStruct      guifg=#4ed99b guibg=NONE guisp=NONE gui=NONE ctermfg=79 ctermbg=NONE cterm=NONE
hi CACECTagsEnumName	guifg=#4ed99b guibg=NONE guisp=NONE gui=NONE ctermfg=79 ctermbg=NONE cterm=NONE
hi CACECTagsEnumValue	guifg=#2ea303 guibg=NONE guisp=NONE gui=NONE ctermfg=121 ctermbg=NONE cterm=NONE
hi CACECTagsMacro		guifg=#ad77d4 guibg=NONE guisp=NONE gui=NONE ctermfg=140 ctermbg=NONE cterm=NONE

function! s:CACECursorMoved()
	if s:caceAsyncProcess == 1
		while len(s:cacePendingSInfoQueue)
			call s:LOGS(s:cacePendingSInfoQueue[0])
			call remove(s:cacePendingSInfoQueue, 0)
		endwhile
	endif
	let s:caceFinding = 0
endfunction

function! s:CACEDumpErrorInfo()
	while len(s:cacePendingEInfoQueue)
		if s:cacePendingEInfoQueue[0] != ''
			" use echoe instead of LOGE to prevent redraw
			echoe s:cacePendingEInfoQueue[0]
		endif
		call remove(s:cacePendingEInfoQueue, 0)
	endwhile
endfunction

function! s:CACEGenerateCMD(cmdid)
	let tdict = s:CACEGetTargetDict()
	let keys = keys(tdict)
	let cmdlist = []
	let cmd = ""
	if a:cmdid == "CACECMD_GREP"
		call add(cmdlist, "/j")
		for key in keys
			let tlist = split(tdict[key])
			for item in tlist
				if key == "name"
					call add(cmdlist,'**/' . item)
				elseif key == "type"
					call add(cmdlist,'**/*.' . item)
				endif
			endfor
		endfor
	elseif a:cmdid == "CACECMD_LST"
		call add(cmdlist, "find -name")
		let isfirst = 1
		for key in keys
			let tlist = split(tdict[key])
			for item in tlist
				if !isfirst
					call add(cmdlist, "-o -name")
				endif
				if key == "name"
					call add(cmdlist,'"' . item . '"')
				elseif key == "type"
					call add(cmdlist,'"*.' . item . '"')
				endif
				let isfirst = 0
			endfor
		endfor
		call add(cmdlist, "> cscope.tags.lst")
	elseif a:cmdid == "CACECMD_CSCOPE"
		call add(cmdlist, 'cscope -bkq -i cscope.tags.lst')
	elseif a:cmdid == "CACECMD_CTAGS"
		call add(cmdlist, 'ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst')
	elseif a:cmdid == "CACECMD_HLE"
		call add(cmdlist, 'vim +Caceupdatehle +q')
	else
		call s:LOGE("Unknown CMD tyep:" . a:cmdid)
	endif
	let cmd = join(cmdlist)
	return cmd
endfunction

function! s:CACEUpdateDB()
	if s:caceAsyncProcess == 1
		let s:caceCWD = getcwd()
		exe 'cd ' . s:CACEGetDBPath('cscope.out')
		call s:CACECleanDB('lst')
		call s:CACEStartJob('lst')
	else
		call s:CACEUpdateDBSync()
	endif
endfunction

function! s:CACERemoveJob(jobname)
	if !has_key(s:caceJobsDict, a:jobname)
		return
	endif
	call remove(s:caceJobsDict, a:jobname)
endfunction

function! s:CACEFlushJobs()
	let keys = keys(s:caceJobsDict)
	for key in keys
		let cnt = 0
		let job = s:caceJobsDict[key]
		while cnt < s:caceRetryCnt
			call job_stop(job)
			if job_status(job) != 'run'
				break
			endif
			let cnt = cnt + 1
		endwhile
		if job_status(job) == 'run'
			call s:LOGE('Failed to stop job ' . key)
		endif
		call s:CACERemoveJob(key)
	endfor
endfunction

function! s:CACEParseMsg(msg)
	let errs = -1
	let erre = -1
	let eqcnt = len(s:cacePendingEInfoQueue)
	if eqcnt > 8
		return ''
	elseif eqcnt == 8
		call s:CACEFlushJobs()
		return ''
	elseif eqcnt > 0 && eqcnt < 8
		let errs = match(a:msg, 'E\d')
		if errs < 0
			call add(s:cacePendingEInfoQueue, '')
		else
			let erre = match(a:msg, '\_$')
			if erre < errs
				let erre = errs + 80
			endif
			call add(s:cacePendingEInfoQueue, strcharpart(a:msg, errs, erre - errs - 1))
		endif
		return ''
	elseif eqcnt == 0
		for esymbol in s:caceMsgErrorSymbols
			let errs = match(a:msg, esymbol)
			if  errs >= 0
				let erre = match(a:msg, '\_$')
				if erre < errs
					let erre = errs + 80
				endif
				call add(s:cacePendingEInfoQueue, strcharpart(a:msg, errs, erre - errs - 1))
				return ''
			endif
		endfor
	endif
	let sidx = match(a:msg, s:caceMsgSymbolDict['start'])
	if sidx < 0
		return ''
	endif
	let sidx = sidx + len(s:caceMsgSymbolDict['start'])
	let eidx = match(a:msg, s:caceMsgSymbolDict['end'])
	if eidx < sidx
		return ''
	endif
	return strcharpart(a:msg, sidx, eidx - sidx )
endfunction

function! s:CACEInfoJobSuccess(str)
	if s:caceFinding == 0
		call s:LOGS(a:str)
	else
		call add(s:cacePendingSInfoQueue, a:str)
	endif
endfunction

function! s:CACEProgressTrace(step)
	if s:caceFinding == 0
		call s:LOGI('Updating DB [' . string(a:step) . '/' . len(s:caceDBDict) . ']')
	endif
endfunction

function! s:CACEJobResponseCb(channel, msg)
	let str = s:CACEParseMsg(a:msg)
	if str != ''
		if s:caceFinding == 0
			call s:LOGI(str)
		endif
	endif
endfunction

function! s:CACELstJobExitCb(job, status)
	let info = job_info(a:job)
	if info['status'] == 'dead'
		call s:CACERemoveJob('lst')
		if len(s:cacePendingEInfoQueue)
			call s:CACEDumpErrorInfo()
			if s:caceCWD != ''
				exe 'cd ' . s:caceCWD
			endif
			return
		endif
		call s:CACEProgressTrace(1)
		let s:caceSkipCscopeReset = 1
		call s:CACECleanDB('cscope')
		call s:CACEStartJob('cscope')
	else
		call s:LOGE('Job lst not finish on exit')
	endif
endfunction

function! s:CACECscopeJobExitCb(job, status)
	let info = job_info(a:job)
	if info['status'] == 'dead'
		call s:CACERemoveJob('cscope')
		if len(s:cacePendingEInfoQueue)
			call s:CACEDumpErrorInfo()
			if s:caceCWD != ''
				exe 'cd ' . s:caceCWD
			endif
			return
		endif
		call s:CACELoadCscopeDB()
		call s:CACEProgressTrace(2)
		call s:CACECleanDB('ctags')
		call s:CACEStartJob('ctags')
	else
		call s:LOGE('Job cscope not finish on exit')
	endif
endfunction

function! s:CACECtagsJobExitCb(job, status)
	let info = job_info(a:job)
	if info['status'] == 'dead'
		call s:CACERemoveJob('ctags')
		if len(s:cacePendingEInfoQueue)
			call s:CACEDumpErrorInfo()
			if s:caceCWD != ''
				exe 'cd ' . s:caceCWD
			endif
			return
		endif
		call s:CACEProgressTrace(3)
		if g:caceHighlightEnhance == 1
			call s:CACEStartJob('hle')
		else
			call s:CACEProgressTrace(4)
			call s:CACEInfoJobSuccess('CACE update success')
		endif
	else
		call s:LOGE('Job ctags not finish on exit')
	endif
endfunction

function! s:CACEHLEJobExitCb(job, status)
	let info = job_info(a:job)
	if info['status'] == 'dead'
		call s:CACERemoveJob('hle')
		if len(s:cacePendingEInfoQueue)
			call s:CACEDumpErrorInfo()
			if s:caceCWD != ''
				exe 'cd ' . s:caceCWD
			endif
			return
		endif
		call s:CACELoadHLEDB()
		call s:CACEProgressTrace(4)
		call s:CACEInfoJobSuccess('CACE update success')
		if s:caceCWD != ''
			exe 'cd ' . s:caceCWD
		endif
	else
		call s:LOGE('Job hle not finish on exit')
	endif
endfunction

let s:caceJobsOptions = {
			\ 'lst' : {
				\ 'callback' : function('s:CACEJobResponseCb'),
				\ 'exit_cb' : function('s:CACELstJobExitCb'),
				\ 'out_io' : 'pipe',
				\ 'err_io' : 'out',
				\ 'timeout' : 2000,
				\ 'out_timeout' : 10000
				\ },
			\ 'cscope' : {
				\ 'callback' : function('s:CACEJobResponseCb'),
				\ 'exit_cb' : function('s:CACECscopeJobExitCb'),
				\ 'out_io' : 'pipe',
				\ 'err_io' : 'out',
				\ 'timeout' : 2000,
				\ 'out_timeout' : 10000
				\ },
			\ 'ctags' : {
				\ 'callback' : function('s:CACEJobResponseCb'),
				\ 'exit_cb' : function('s:CACECtagsJobExitCb'),
				\ 'out_io' : 'pipe',
				\ 'err_io' : 'out',
				\ 'timeout' : 2000,
				\ 'out_timeout' : 10000
				\ },
			\ 'hle' : {
				\ 'callback' : function('s:CACEJobResponseCb'),
				\ 'exit_cb' : function('s:CACEHLEJobExitCb'),
				\ 'out_io' : 'pipe',
				\ 'err_io' : 'out',
				\ 'timeout' : 2000,
				\ 'out_timeout' : 10000
				\ }
			\ }

function! s:CACEStartJob(jobname)
	if len(s:caceJobsDict)
		return
	endif
	let cmdlst = []
	call add(cmdlst, '/bin/sh')
	call add(cmdlst, '-c')
	let cmd = s:CACEGenerateCMD(s:caceJobCmdId[a:jobname])
	call add(cmdlst, cmd)
	let options = s:caceJobsOptions[a:jobname]
	let s:caceJobsDict[a:jobname] = job_start(cmdlst, options)
	let jobstatus = job_status(s:caceJobsDict[a:jobname])
	if jobstatus != 'run'
		call s:LOGE('faild to start async job for DB update')
	endif
endfunction

function! s:CACECscopeQuickfixTrigger()
	if &cscopequickfix==""
		setlocal cscopequickfix=s-,c-,d-,i-,t-,e-
	else
		setlocal cscopequickfix=
	endif
	call s:LOG("cscopequickfix=" . &cscopequickfix)
endfunction

function! s:CACEGrepFunc(target)
	let s:caceCWD = getcwd()
	exe "cd " . s:CACEGetDBPath("cscope.out")
	call s:LOGI("Searching ...")
	exe "silent vimgrep /" . a:target . s:CACEGenerateCMD('CACECMD_GREP')
	redraw
	call s:LOGI(" ")
	exe "cd " . s:caceCWD
	let @/ = a:target
	exe "copen"
endfunction

function! s:CACEcscopeFind(mode, target)
	if !has_key(s:caceCscopeFindModeDict, a:mode) || s:caceCscopeFindModeDict[a:mode] != 1
		call s:LOGE("Invalid mode: " . a:mode)
		return
	endif
	let s:caceFinding = 1
	exe "cs find " . a:mode . " " . a:target
	if &cscopequickfix !=""
		exe "cw"
	endif
endfunction

function! s:CACEGetTargetDict()
	let tdict = {}
	let namelist = []
	let typelist = []
	let keys = keys(s:caceTargetFileTypeMap)
	for key in keys
		let tlist = split(s:caceTargetFileTypeMap[key])
		for target in tlist
			if strpart(target, 0, 1) == "."
				call add(typelist, strpart(target, 1))
			else
				call add(namelist, target)
			endif
		endfor
	endfor
	let tdict['name'] = join(namelist)
	let tdict['type'] = join(typelist)
	return tdict
endfunction

function! s:CACELoadHLEDB()
	let filetype = expand('%:e')
	let tdict = s:CACEGetTargetDict()
	let keys = keys(tdict)
	let typevalid = 0
	for key in keys
		let tlist = split(tdict[key])
		for item in tlist
			if filetype == item
				let typevalid = 1
				break
			endif
		endfor
		if typevalid
			break
		endif
	endfor
	if !typevalid
		return
	endif
	let hledb = findfile(s:caceDBDict['hle'], getcwd() . ";")
	if (empty(hledb))
		return
	endif
	let keys = keys(s:caceHLESupportedGroupMap)
	for key in keys
		exe "syntax clear " . s:caceHLESupportedGroupMap[key]
	endfor
	exe "source " . hledb
endfunction

function! s:CACELoadCscopeDB()
	if !s:caceSkipCscopeReset
		" kill will disconnect db. but will leads find error. Use reset instead.
		silent exe "cs reset"
	endif
	let db = findfile("cscope.out", ".;")
	if (!empty(db))
		let path = strpart(db, 0, match(db, "/cscope.out$"))
		setlocal nocscopeverbose
		exe "cs add " . db . " " . path
		let s:caceSkipCscopeReset = 0
		setlocal cscopeverbose
	elseif $CSCOPE_DB != ""
		exe "cs add " . $CSCOPE_DB
		let s:caceSkipCscopeReset = 0
	endif
endfunction

function! s:CACELoadDB()
	call s:CACELoadCscopeDB()
	if g:caceHighlightEnhance == 1
		call s:CACELoadHLEDB()
	endif
	return 0
endfunction

function! s:CACEGenerateMsg(str)
	return s:caceMsgSymbolDict["start"] . a:str . s:caceMsgSymbolDict["end"]
endfunction

function! s:CACEGetDBPath(dbname)
	let db = findfile(a:dbname, getcwd() . ";")
	let dbpath = getcwd()
	if (!empty(db))
		if (db != a:dbname)
			let dbpath = strpart(db, 0, match(db, "/" . a:dbname . "$"))
		endif
	endif
	return dbpath
endfunction

function! s:CACECleanDB(target)
	let keys = keys(s:caceDBDict)
	for key in keys
		if a:target == 'all' || a:target == key
			let dbs = split(s:caceDBDict[key])
			for db in dbs
				call delete(db)
			endfor
			if a:target == key
				break
			endif
		endif
	endfor
endfunction

function! s:CACEUpdateDBSync()
	let rt = 0
	let s:caceCWD = getcwd()
	exe "cd " . s:CACEGetDBPath("cscope.out")
	call s:CACECleanDB('lst')
	call system(s:CACEGenerateCMD('CACECMD_LST'))
	call s:CACEProgressTrace(1)
	call s:CACECleanDB('cscope')
	call system('cscope -bkq -i cscope.tags.lst')
	call s:CACELoadCscopeDB()
	call s:CACEProgressTrace(2)
	call s:CACECleanDB('ctags')
	call system('ctags -R --c++-kinds=+p --fields=+iaS --extra=+q < cscope.tags.lst')
	call s:CACEProgressTrace(3)
	let rt = s:CACEUpdateHLE()
	if rt
		return
	endif
	call s:CACELoadHLEDB()
	call s:CACEProgressTrace(4)
	if rt
		return
	endif
	exe "cd " . s:caceCWD
	call s:LOGS("CACE update success\n")
	exe "cs show"
endfunction

function! s:CACEIsHLESuopprted(type)
	if strlen(a:type) > 1
		return 0
	endif
	let keys = keys(s:caceHLESupportedGroupMap)
	for key in keys
		if char2nr(a:type) == char2nr(key)
			return 1
		endif
	endfor
	return 0
endfunction

function! s:CACEHLEUpdateTrace(index, total)
	if s:caceAsyncProcess == 1
		redraw
		let msg = s:CACEGenerateMsg('Updating HLE [' . string(a:index * 100 / a:total) . '%]')
		exe 'echom "' . msg . '"'
		!echo ''
	else
		call s:LOGI('Updating HLEDB [' . string(a:index * 100 / a:total) . '%]')
	endif
endfunction

function! s:CACEUpdateHLE()
	if g:caceHighlightEnhance == 0
		return 0
	endif
	let tag = findfile(s:caceDBDict["ctags"], ".;")
	if (empty(tag))
		call s:LOGE("Update HLE failed. Cannot find: " . s:caceDBDict["ctags"])
		return 1
	endif
	let taglines = readfile(s:caceDBDict["ctags"])
	if empty(taglines)
		call s:LOGE("Update HLE failed. Tag is empty: " . s:caceDBDict["ctags"])
		return 1
	endif

	call filter(s:caceHLEUniquePatternDict, 0)
	let ctagsdict = s:CACEParseCtag(taglines)
	call filter(s:caceHLEUniquePatternDict, 0)

	let wlines = []
	let keys = keys(ctagsdict)
	for key in keys
		if s:CACEIsHLESuopprted(strcharpart(key, 0, 1))
			call add(wlines, "syntax keyword " . s:caceHLESupportedGroupMap[strcharpart(key, 0, 1)] . " " . ctagsdict[key])
		endif
	endfor
	call s:CACECleanDB('hle')
	if len(wlines)
		call writefile(wlines, "cscope.tags.hle")
	endif

	let keys = keys(s:caceHLESupportedGroupMap)
	for key in keys
		exe "syntax clear " . s:caceHLESupportedGroupMap[key]
	endfor

	return 0
endfunction

function! s:CACEHLEPatternInvalid(pattern)
	" Single char is not expected to be highlighted
	" Vim highlight spec: keyword length < 80. Please check: syn-keyword
	if strlen(a:pattern) < 2 || strlen(a:pattern) > 80
		return 1
	endif

	" keyword cannot be syn-argument. Please check: syn-arguments
	let keys = keys(s:caceHLEInvalidKeywordDict)
	for key in keys
		let invalidkeywordlist = split(s:caceHLEInvalidKeywordDict[key])
		for word in invalidkeywordlist
			if a:pattern == word
				return 1
			endif
		endfor
	endfor

	" Only highlight a pattern onece
	if has_key(s:caceHLEUniquePatternDict, a:pattern)
		return 1
	else
		let s:caceHLEUniquePatternDict[a:pattern] = 1
	endif

	return 0
endfunction

function! s:CACEParseCtag(lines)
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

		if !s:CACEIsHLESuopprted(tagtype)
			continue
		endif

		let pattern = split(line)[0]
		if  len(split(pattern, "::")) > 1
			let pattern = split(pattern, "::")[len(split(pattern, "::")) - 1]
		endif
		if s:CACEHLEPatternInvalid(pattern)
			continue
		endif

		if !has_key(multitypemap, tagtype)
			let multitypemap[tagtype] = "0:0"
			let tagtype = tagtype . "0"
		else
			let typecnt = split(multitypemap[tagtype], ":")[0]
			let wordcnt = split(multitypemap[tagtype], ":")[1]
			if str2nr(wordcnt, 10) < s:caceHLEWordsNumPerLine
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
			call s:CACEHLEUpdateTrace(linecnt, linenum)
		endif
	endfor
	return ctagsdict
endfunction

function! s:LOG(str)
	let newstr = ' ' . a:str
	echo newstr
endfunction
function! s:LOGI(str)
	let newstr = ' ' . a:str
	redraw
	echohl Type | echo newstr | echohl None
endfunction
function! s:LOGW(str)
	let newstr = ' ' . a:str
	echohl WarningMsg | echo newstr | echohl None
endfunction
function! s:LOGE(str)
	let newstr = ' ' . a:str
	echohl ErrorMsg | echo newstr | echohl None
endfunction
function! s:LOGS(str)
	let newstr = ' ' . a:str
	redraw
	echohl Comment | echo newstr | echohl None
endfunction

