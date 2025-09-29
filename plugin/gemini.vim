" Arquivo: plugin/gemini.vim

" Verifica se o comando 'gemini' (CLI) está disponível no sistema
if executable('gemini') == 0
    echohl Warning | echom "Gemini CLI not found! Please install it (e.g., npm install -g @google/gemini-cli) and ensure your API key is set." | echohl None
    finish
endif

" =========================================================
" FUNÇÃO CENTRAL: gemini#CallOnRange
" Lida com a seleção de código, chamada do CLI e inserção da resposta.
" =========================================================
function! gemini#CallOnRange(initial_prompt) abort range
    " 1. Obtém o texto selecionado
    let l:code_to_process = join(getline(a:firstline, a:lastline), "\n")
    
    " 2. Constrói o prompt (incluindo o código selecionado para contexto)
    let l:full_prompt = a:initial_prompt . ":\n\n```\n" . l:code_to_process . "\n```"

    " 3. Chama o Gemini CLI
    echom "Calling Gemini CLI... (This may take a moment)"
    " O comando CLI é executado. A saída é capturada.
    " shellescape() garante que o prompt seja seguro para o shell.
    let l:gemini_response = system("echo " . shellescape(l:full_prompt) . " | gemini")
    
    " 4. Tenta extrair o bloco de código do Gemini (usando regex para ```...)
    " 'm' flag é crucial para que '^' e '$' funcionem como início/fim de linha
    let l:code_block = matchlist(l:gemini_response, '^\s*```\S*\s*\n\zs.*\ze^\s*```\s*$', 'm')

    if !empty(l:code_block)
        " 5. SE um bloco de código for encontrado, insere de volta
        let l:new_lines = split(l:code_block[0], '\n')
        
        " Deleta as linhas antigas
        execute a:firstline . ',' . a:lastline . 'd'
        " Insere as novas linhas na posição original
        call append(a:firstline - 1, l:new_lines)
    else
        " 5. SENÃO, exibe a resposta inteira do Gemini no Command Line
        echohl Error | echom "Gemini did not return a code block (```...```)." | echohl None
        echom "Full Response:"
        echom l:gemini_response
    endif
endfunction

" =========================================================
" DEFINIÇÃO DOS COMANDOS
" Todos usam -range=% para funcionar na seleção visual.
" =========================================================

" Comando base para Refatorar com prompt livre (EX: :Gemini refatore...)
command! -range=% -nargs=+ Gemini call gemini#CallOnRange(<f-args>)

" Explica o Código (EX: :GeminiExplain)
command! -range=% -nargs=0 GeminiExplain call gemini#CallOnRange("Explique detalhadamente este bloco de código. Use Markdown para formatar a explicação e não altere o código.")

" Gera Testes Unitários (EX: :GeminiUnitTest)
command! -range=% -nargs=0 GeminiUnitTest call gemini#CallOnRange("Gere testes unitários abrangentes para este bloco de código usando o framework de testes mais apropriado para a linguagem. Apenas o código dos testes deve ser a resposta.")

" Otimiza o Código (Performance/Recursos) (EX: :GeminiOptimize)
command! -range=% -nargs=0 GeminiOptimize call gemini#CallOnRange("Otimize este código para melhor performance e uso de recursos. Forneça apenas o código otimizado como um desenvolvedor principal.")

" Adiciona Comentários/Documentação (EX: :GeminiDoc)
command! -range=% -nargs=0 GeminiDoc call gemini#CallOnRange("Adicione comentários e documentação detalhada (incluindo docstrings/jsdocs, se aplicável) a este bloco de código, mantendo o código existente.")
