" File:         simpletest.vim
" Author:       xwsoul (xwsoul@gmail.com)
" Modified:     2011-07-26 14:54

if !exists("g:simpletest_command")
  let simpletest_command = 'php'
endif

if !exists("g:simpletest_highlight_color")
  let simpletest_highlight_color = 'DarkMagenta'
endif

" Runs the current file through javascript lint and
" opens a quickfix window with any warnings
function PHPSimpleTest()
  " run javascript lint on the current file
  let current_file = shellescape(expand('%:p'))
  let cmd_output = system(g:simpletest_command . ' ' . current_file)

  if match(cmd_output, 'OK') == -1

    let out = []
    for line in split(cmd_output, "\n")
    if match(line, 'Expected .*, got') != -1
        call add(out, line)
    elseif match(line, "Test cases run: ") != -1
        call add(out, line)
    endif
	endfor
	let l:error_info = join(out, "\n")
	echo l:error_info

    " ensure proper error format
    set errorformat +=%m\ at\ \[%f\ line\ %l\]

    " write quickfix errors to a temp file
    let quickfix_tmpfile_name = tempname()
    exe "redir! > " . quickfix_tmpfile_name
      silent echon l:error_info
    redir END

    " read in the errors temp file 
    execute "silent! cfile " . quickfix_tmpfile_name

    " change the cursor line to something hard to miss
    call s:SetCursorLineColor()

    " open the quicfix window
    botright copen
    let s:qfix_buffer = bufnr("$")

    " delete the temp file
    call delete(quickfix_tmpfile_name)

  " if no javascript warnings are found, we revert the cursorline color
  " and close the quick fix window
  else
    for line in split(cmd_output, "\n")
        if match(line, "Test cases run: ") != -1
            echo line
        endif
    endfor
    call s:ClearCursorLineColor()
    if(exists("s:qfix_buffer"))
      cclose
      unlet s:qfix_buffer
    endif
  endif
endfunction

" sets the cursor line highlight color to the error highlight color 
function s:SetCursorLineColor()
  " check for disabled cursor line
  if(!exists("g:simpletest_highlight_color") || strlen(g:simpletest_highlight_color) == 0)
    return 
  endif

  call s:ClearCursorLineColor()
  let s:highlight_on = 1

  " find the current cursor line highlight info
  redir => l:highlight_info
    silent highlight CursorLine
  redir END

  " find the guibg property within the highlight info (if it exists)
  let l:start_index = match(l:highlight_info, "guibg")
  if(l:start_index > 0)
    let s:previous_cursor_guibg = strpart(l:highlight_info, l:start_index)

  elseif(exists("s:previous_cursor_guibg"))
    unlet s:previous_cursor_guibg
  endif

  execute "highlight CursorLine guibg=" . g:simpletest_highlight_color
endfunction

" Conditionally reverts the cursor line color based on the presence
" of the quickfix window
function s:MaybeClearCursorLineColor()
  if(exists("s:qfix_buffer") && s:qfix_buffer == bufnr("%"))
    call s:ClearCursorLineColor()
  endif
endfunction

" Reverts the cursor line color
function s:ClearCursorLineColor()
  " only revert if our highlight is currently enabled
  if(exists("s:highlight_on") && s:highlight_on) 
    let s:highlight_on = 0

    " if a previous cursor guibg color was recorded, we use it
    if(exists("s:previous_cursor_guibg"))
      execute "highlight CursorLine " . s:previous_cursor_guibg
      unlet s:previous_cursor_guibg

    " otherwise, we clear the curor line highlight entirely
    else
      highlight clear CursorLine
    endif
  endif
endfunction
