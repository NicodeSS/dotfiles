#!/usr/bin/env bash

if command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --bind "ctrl-/:toggle-preview"
'

export FZF_ALT_C_OPTS="--preview 'ls -la {}'"

ff() {
    local file
    file=$(fzf --preview 'cat {}' --preview-window=right:60%:wrap)
    [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}

fcd() {
    local dir
    dir=$(find ${1:-.} -type d 2>/dev/null | fzf --preview 'ls -la {}')
    [[ -n "$dir" ]] && cd "$dir"
}

fkill() {
    local pid
    if [[ "$UID" != "0" ]]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi
    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

fenv() {
    local var
    var=$(printenv | fzf)
    [[ -n "$var" ]] && echo "$var"
}

fh() {
    local cmd
    cmd=$(history | fzf --tac | sed 's/^[ ]*[0-9]*[ ]*//')
    [[ -n "$cmd" ]] && print -z "$cmd"
}

fgb() {
    local branch
    branch=$(git branch -a | fzf | sed 's/^[* ]*//' | sed 's/remotes\/origin\///')
    [[ -n "$branch" ]] && git checkout "$branch"
}

fgwt() {
    git worktree list | fzf --preview 'git log --oneline -10 {2}' | awk '{print $1}'
}

fgwtcd() {
    local wt
    wt=$(git worktree list | fzf --preview 'ls -la {1}' | awk '{print $1}')
    [[ -n "$wt" ]] && cd "$wt"
}

fgwtrm() {
    local wt
    wt=$(git worktree list | fzf --preview 'git log --oneline -10 {2}' | awk '{print $1}')
    [[ -n "$wt" ]] && git worktree remove "$wt"
}

fgwtab() {
    local branch
    branch=$(git branch -a | fzf | sed 's/^[* ]*//' | sed 's/remotes\/origin\///')
    if [[ -n "$branch" ]]; then
        local dir="../${branch##*/}"
        git worktree add "$dir" "$branch" && cd "$dir"
    fi
}

alias rga='rg --hidden --no-ignore'
alias rgi='rg -i'
alias rgf='rg --files | rg'
