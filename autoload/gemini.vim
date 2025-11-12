" ============================================================================
" File: autoload/gemini.vim
" Description: Core logic for the Gemini chat integration in Vim.
" Author: Sergio Bonatto
" License: MIT
============================================================================

let s:job = v:null
let s:chat_bufnr = -1
let s:last_user_line = 0

" --- Public Functions ---

" Opens the chat window and starts the Gemini process.
function! gemini#Start() abort
  if s:is_chat_open()
    call s:focus_chat_window()
    return
  endif

  let width = get(g:, 'gemini_terminal_width', 80)
  execute 'botright ' . width . 'vsplit'
  enew
  let s:chat_bufnr = bufnr('%')

  call s:setup_chat_buffer()
  call s:start_job()
endfunction

" Sends the user's message to the Gemini process.
function! gemini#Send() abort
  if s:job is v:null || job_status(s:job) != 'run'
    echohl ErrorMsg
    echo "Error: Gemini process is not running."
    echohl None
    return
  endif

  let user_input = getline(s:last_user_line)
  if empty(trim(user_input))
    return
  endif

  " Send to job
  call ch_sendraw(s:job, user_input . "\n")

  " Update buffer
  call setline(s:last_user_line, 'You: ' . user_input)
  call s:prepare_next_prompt()
endfunction

" Handles sending a visual selection to the chat.
function! gemini#SendVisualSelection(prompt) abort
  if !s:is_chat_open()
    call gemini#Start()
    " Give the job a moment to start up
    sleep 100m
  endif
  call s:focus_chat_window()

  let filetype = getbufvar(bufnr(''), '&filetype')
  let code_block = printf("```%s\n%s\n```", filetype, getreg('"'))
  let full_prompt = a:prompt . "\n" . code_block

  " Append prompt and code block to chat
  call s:append_to_chat(split(full_prompt, '\n'))

  " Send to job
  if s:job isnot v:null && job_status(s:job) == 'run'
    call ch_sendraw(s:job, full_prompt . "\n")
  endif
  call s:prepare_next_prompt()
endfunction


" --- Private Functions ---

function! s:is_chat_open() abort
  return s:chat_bufnr != -1 && bufexists(s:chat_bufnr) && bufwinnr(s:chat_bufnr) != -1
endfunction

function! s:focus_chat_window() abort
  execute bufwinnr(s:chat_bufnr) . 'wincmd w'
endfunction

function! s:setup_chat_buffer() abort
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nobuflisted
  setlocal filetype=gemini-chat
  setlocal syntax=markdown
  setlocal wrap
  setlocal nospell

  " Mapping for sending a message.
  inoremap <buffer><silent> <CR> <Esc>:call gemini#Send()<CR>

  call setline(1, 'Welcome to Gemini Chat!')
  call s:prepare_next_prompt()
endfunction

function! s:prepare_next_prompt() abort
  " Add a new line for the user to type in.
  call append(line('$'), '')
  let s:last_user_line = line('$')
  call cursor(s:last_user_line, 1)
  startinsert
endfunction

function! s:append_to_chat(lines) abort
  if !bufexists(s:chat_bufnr)
      return
  endif
  " Append the text to the buffer, before the user's input line.
  call appendbufline(s:chat_bufnr, s:last_user_line - 1, a:lines)
  let s:last_user_line += len(a:lines)

  " Redraw window to show new content
  let winid = bufwinid(s:chat_bufnr)
  if winid != -1
      call win_execute(winid, 'normal! G')
  endif
endfunction

function! s:start_job() abort
  let cmd = get(g:, 'gemini_cmd_base', 'gemini')
  if !executable(cmd)
      call s:append_to_chat(['Error: ' . cmd . ' command not found.', 'Please ensure `gemini` is installed and in your PATH.'])
      return
  endif

  let s:job = job_start(cmd, {
        \ 'out_cb': {channel, msg -> s:handle_output(channel, msg)},
        \ 'err_cb': {channel, msg -> s:handle_output(channel, msg)},
        \ 'exit_cb': {job, exit_code -> s:handle_exit(job, exit_code)},
        \ 'pty': v:true,
        \ })

  if job_status(s:job) != 'run'
    call s:append_to_chat(['Error: Could not start the gemini process.'])
    let s:job = v:null
  endif
endfunction

function! s:handle_output(channel, msg) abort
  " The PTY might send back the user's own input. We'll try to filter that.
  let user_input = getline(s:last_user_line - 1)
  if stridx(user_input, a:msg) == -1
    call s:append_to_chat(['Gemini: ' . a:msg])
  endif
endfunction

function! s:handle_exit(job, exit_code) abort
  call s:append_to_chat(['', 'Gemini process finished. Exit code: ' . a:exit_code, 'You can close this window or start a new chat with :GeminiChat'])
  let s:job = v:null
endfunction

" vim: set et sw=2 ts=2 sts=2 foldmethod=marker:
