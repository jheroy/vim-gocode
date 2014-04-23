" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" fmt.vim: Vim command to format Go files with gofmt.
"
" This filetype plugin add a new commands for go buffers:
"
"   :Fmt
"
"       Filter the current Go buffer through gofmt.
"       It tries to preserve cursor position and avoids
"       replacing the buffer with stderr output.
"
" Options:
"
"   g:go_fmt_commands [default=1]
"
"       Flag to indicate whether to enable the commands listed above.
"
"   g:gofmt_command [default="gofmt"]
"
"       Flag naming the gofmt executable to use.
"
if exists("b:did_ftplugin_go_fmt")
    finish
endif

if !exists("g:go_fmt_commands")
    let g:go_fmt_commands = 1
endif

if g:go_fmt_commands
    command! -buffer Fmt call s:GoFormat()
endif

if !exists('g:go_fmt_autofmt')
    let g:go_fmt_autofmt = 1
endif

if g:go_fmt_autofmt
    " Run gofmt before saving file
    autocmd BufWritePre <buffer> :keepjumps Fmt " thanks @justinmk
endif

if !exists("g:gofmt_command")
    let g:gofmt_command = "gofmt"
endif

function! s:GoFormat()
    let view = winsaveview()

    " If spaces are used for indents, configure gofmt

    let tabs = ''
    if g:gofmt_command == "gofmt"
        if &expandtab
            let tabs = ' -tabs=false -tabwidth=' . (&sw ? &sw : (&sts ? &sts : &ts))
        endif
    endif

    silent execute "%!" . g:gofmt_command . tabs

    if v:shell_error
        let errors = []
        for line in getline(1, line('$'))
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
            if !empty(tokens)
                call add(errors, {"filename": @%,
                                 \"lnum":     tokens[2],
                                 \"col":      tokens[3],
                                 \"text":     tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect gofmt error format, output errors
        endif
        undo
        if !empty(errors)
            call setloclist(0, errors, 'r')
        endif
        echohl Error | echomsg "Gofmt returned error" | echohl None
    endif
    call winrestview(view)
endfunction

let b:did_ftplugin_go_fmt = 1

" vim:sw=4:et
