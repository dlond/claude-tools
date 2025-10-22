#!/bin/bash
# Bash completion for claude-tools

_claude_ls_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local sources

    # Get all available sources (including ghosts)
    sources=$(claude-ls --complete 2>/dev/null | cut -f1)

    COMPREPLY=($(compgen -W "$sources" -- "$cur"))
}

_claude_cp_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local sources

    # Determine position
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        # First argument - source (include ghosts)
        sources=$(claude-cp --complete-source 2>/dev/null | cut -f1)
        COMPREPLY=($(compgen -W "$sources" -- "$cur"))
    elif [[ ${COMP_CWORD} -eq 2 ]]; then
        # Second argument - destination (only real directories)
        COMPREPLY=($(compgen -d -- "$cur"))
    elif [[ ${COMP_CWORD} -eq 3 ]]; then
        # Third argument - conversation ID or --
        if [[ "$cur" == "-"* ]]; then
            COMPREPLY=("--")
        else
            # Get conversations from source directory
            local source="${COMP_WORDS[1]}"
            local conversations=$(claude-cp "$source" /tmp -- 2>/dev/null | cut -f1)
            COMPREPLY=($(compgen -W "$conversations" -- "$cur"))
        fi
    fi
}

# Register completions
complete -F _claude_ls_completions claude-ls
complete -F _claude_cp_completions claude-cp