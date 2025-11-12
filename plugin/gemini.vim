" ============================================================================
" File: plugin/gemini.vim
" Description: Gemini chat integration for Vim.
" Author: Sergio Bonatto
" License: MIT
" ============================================================================

if exists('g:loaded_gemini_chat') || &compatible
  finish
endif
let g:loaded_gemini_chat = 1

let s:save_cpo = &cpo
set cpo&vim

" ============================================================================
" Commands
" ============================================================================

" Opens the main Gemini chat window.
command! GeminiChat call gemini#Start()

" Sends the visual selection to the chat with a prompt.
command! -range -nargs=1 GeminiChatVisual <line1>,<line2>call s:VisualChat(<f-args>)

" ============================================================================
" Mappings
" ============================================================================

" Open the Gemini chat window.
nnoremap <silent> <Leader>gc :GeminiChat<CR>

" Send visual selection to Gemini to be explained.
vnoremap <silent> <Leader>ge :<C-U>GeminiChatVisual 'Explain this code:'<CR>

" Send visual selection to Gemini to be refactored.
vnoremap <silent> <Leader>gr :<C-U>GeminiChatVisual 'Refactor this code:'<CR>

" Send visual selection to Gemini to add tests.
vnoremap <silent> <Leader>gt :<C-U>GeminiChatVisual 'Write tests for this code:'<CR>

" ============================================================================
" Private Functions
" ============================================================================

" Wrapper function to handle visual selection.
" It yanks the selection and calls the core function.
function! s:VisualChat(prompt) range
  " The < and > marks are set by the visual selection range
  silent execute a:firstline . ',' . a:lastline . 'y'
  call gemini#SendVisualSelection(a:prompt)
endfunction

" ============================================================================
" Cleanup
" ============================================================================

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set et sw=2 ts=2 sts=2:
