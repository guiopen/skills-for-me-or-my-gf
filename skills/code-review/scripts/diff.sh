#!/usr/bin/env bash
set -e

echo "=== CHANGED AND STAGED/MODIFIED FILES (VS LAST COMMIT) ==="
# Captura a lista de arquivos modificados (após filtro de lockfiles)
changed_files=$(git diff HEAD --name-only | grep -vE '((package|pnpm|vcpkg)-lock\.|\.lock(file)?$|go\.sum$)' || true)

if [ -z "$changed_files" ]; then
    echo "none"
else
    # Converte a lista para null‑separated e executa o diff
    printf '%s\n' "$changed_files" | tr '\n' '\0' | xargs -0 -r git diff HEAD --
fi

echo -e "\n=== UNTRACKED NEW FILES ==="
# Captura a lista de arquivos não rastreados (após filtro de lockfiles)
untracked_files=$(git ls-files --others --exclude-standard | grep -vE '((package|pnpm|vcpkg)-lock\.|\.lock(file)?$|go\.sum$)' || true)

if [ -z "$untracked_files" ]; then
    echo "(none)"
else
    # Processa apenas arquivos não binários e armazena a saída em uma variável
    output=$(printf '%s\n' "$untracked_files" | tr '\n' '\0' | xargs -0 -I{} sh -c '
        file --mime-encoding -b "{}" | grep -qv binary &&
        printf "\n\n=== NEW FILE: %s ===\n" "{}" &&
        cat "{}"
    ' 2>/dev/null || true)

    if [ -z "$output" ]; then
        echo "(none)"
    else
        printf '%s\n' "$output"
    fi
fi

echo -e "\n=== RECENT COMMIT HISTORY (FOR CONTEXT) ==="
git --no-pager log --oneline -20 || echo "(no git history)"
