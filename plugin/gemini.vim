" ============================================================================
" File: gemini_runner.vim
" Description: Split vertical e execução do 'gemini cli' no terminal embutido.
" Author: Sergio Bonatto
" License: MIT
" ============================================================================

if exists('g:loaded_gemini_runner') || &compatible
finish
endif
let g:loaded_gemini_runner = 1

" Salva as opções de compatibilidade
let s:save_cpo = &cpo
set cpo&vim

" ============================================================================
" Variáveis de Configuração (Opcional)
" ============================================================================

" Comando base a ser executado no terminal.
let g:gemini_cmd_base = get(g:, 'gemini_cmd_base', 'gemini')

" Largura da janela do terminal em colunas (0 para usar a divisão padrão).
let g:gemini_terminal_width = get(g:, 'gemini_terminal_width', 60)

" ============================================================================
" Função Principal
" ============================================================================

" Executa o comando Gemini em um split vertical.
function! s:RunGeminiSplit() abort
" Verifica se o Vim/Neovim suporta o terminal embutido
if !has('terminal')
    echohl ErrorMsg
    echo "Erro: Esta versão do Vim/Neovim não suporta o terminal embutido."
    echohl None
    return
endif

" 1. Salva o arquivo atual (boa prática antes de mudar o contexto)
if &modified
    try
        write
    catch /^Vim\%((\a\+)\)\=:E/
        echohl WarningMsg
        echo "Aviso: Não foi possível salvar o arquivo."
        echohl None
    endtry
endif

" 2. Constrói o comando: Split vertical e abre o terminal com o comando.
" O 'botright' garante que o novo split apareça à direita.
let l:cmd_to_exec = 'vertical botright terminal ' . g:gemini_cmd_base

" 3. Executa o split e o terminal.
execute l:cmd_to_exec
" Move o foco para a janela recém-criada (à direita) para que você possa digitar
wincmd l

" 4. Redimensiona a janela do terminal, se configurado.
if g:gemini_terminal_width > 0
    " Move o foco para a janela recém-criada (à direita)
    wincmd l
    " Redimensiona o split verticalmente
    execute 'vertical resize ' . g:gemini_terminal_width
    " Retorna o foco para a janela do código
    wincmd h
endif
endfunction

" ============================================================================
" Mapeamento de Tecla
" ============================================================================

" Mapeia <Leader>G para chamar a função de execução.
" <Leader> é uma tecla prefixo (geralmente \) para comandos customizados.
nnoremap <silent> <Leader>G :call <SID>RunGeminiSplit()<CR>

" ============================================================================
" Comandos Públicos (Opcional)
" ============================================================================

" Comando para execução manual: :GeminiRun
command! GeminiRun call <SID>RunGeminiSplit()

" ============================================================================
" Limpeza
" ============================================================================

" Restaura as opções de compatibilidade
let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set et sw=4 ts=4 sts=4:
