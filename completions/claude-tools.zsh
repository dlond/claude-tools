#!/bin/zsh
# Zsh completion for claude-tools

_claude_ls() {
    local -a sources
    sources=(${(f)"$(claude-ls --complete 2>/dev/null | cut -f1)"})

    _arguments \
        '1:source directory:(($sources))'
}

_claude_cp() {
    local state

    _arguments \
        '1:source directory:->source' \
        '2:destination directory:->dest' \
        '3:conversation id or --:->id' \
        '--dry-run[show what would be done]' \
        '--verbose[show detailed output]' \
        '--exec[launch Claude after copying]'

    case "$state" in
        source)
            # First argument - include ghost directories
            local -a sources
            sources=(${(f)"$(claude-cp --complete-source 2>/dev/null | cut -f1)"})
            _describe 'source directory' sources
            ;;
        dest)
            # Second argument - only real directories
            _path_files -/
            ;;
        id)
            # Third argument - conversation IDs from source
            local source="${words[2]}"
            if [[ -n "$source" ]]; then
                local -a conversations
                conversations=(${(f)"$(claude-cp "$source" /tmp -- 2>/dev/null | cut -f1)"})
                conversations+=("--")
                _describe 'conversation' conversations
            fi
            ;;
    esac
}

# Register completions
compdef _claude_ls claude-ls
compdef _claude_cp claude-cp