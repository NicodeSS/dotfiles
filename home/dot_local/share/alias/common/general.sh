# General
alias _='sudo'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias dud='du -h -d 1'
alias duf='du -sh'
alias free='free -h' # Human-readable memory usage
alias t='tail -f'
alias unexport='unset'
alias free='free -h' # Human-readable memory usage
alias top='htop'     # Use htop instead of top if installed
alias cls='clear'
alias path='echo -e ${PATH//:/\\n}' # Print PATH variable line by line

# Function to create a directory and navigate into it
mkcd() {
    if [ -z "$1" ]; then
        echo "用法: mkcd <目录名>"
        return 1
    fi
    mkdir -p "$@" && cd "${@:$#}"
}

# Function to display the current date and time in a human-readable format
datetime() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to display system information
sysinfo() {
    echo "操作系统: $(uname -s)"
    echo "主机名: $(hostname)"
    echo "内核版本: $(uname -r)"
    echo "处理器架构: $(uname -m)"
    echo "当前用户: $(whoami)"
    echo "当前时间: $(date +"%Y-%m-%d %H:%M:%S")"
}

# Find & grep
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS}'

# Function to search for a string in files within the current directory
search() {
    if [ -z "$1" ]; then
        echo "用法: search <字符串>"
        return 1
    fi
    grep -rnw . -e "$1"
}
# Function to find files by name in the current directory
findf() {
    if [ -z "$1" ]; then
        echo "用法: findf <文件名>"
        return 1
    fi
    find . -type f -name "*$1*"
}
# Function to find directories by name in the current directory
findd() {
    if [ -z "$1" ]; then
        echo "用法: findd <目录名>"
        return 1
    fi
    find . -type d -name "*$1*"
}

# Editor
alias vi='nvim' # Use neovim as the default editor
alias vim='nvim'

# Conf file
alias zshconf='${=EDITOR} ~/.zshrc'
alias zshcommit='source ~/.zshrc'
alias sshconf='${=EDITOR} ~/.ssh/config'
alias tmuxconf='${=EDITOR} ~/.tmux.conf'
alias hosts='sudo -e /etc/hosts'

# Proxy
alias enproxy='
export http_proxy=;
export https_proxy=;
'
alias unproxy='
    unset http_proxy;
    unset https_proxy;
'

# ls
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# history
alias h='history'
alias hl='history | less'
alias hs='history | grep'
alias hsi='history | grep -i'

# rsync
_rsync_cmd='rsync --verbose --archive --compress --human-readable --progress'
alias rsync-copy='${_rsync_cmd}'
alias rsync-move='${_rsync_cmd} --remove-source-files'
alias rsync-update='${_rsync_cmd} --update'
alias rsync-sync='${_rsync_cmd} --update --delete'

# QRcode
qrcode() {
    if [ -z "$1" ]; then
        echo "Usage: qrcode <text>"
        return 1
    fi
    curl -d "$1" qrcode.show
}

qrsvg() {
    if [ -z "$1" ]; then
        echo "Usage: qrsvg <text>"
        return 1
    fi
    curl -d "$1" qrcode.show -H "Accept: image/svg+xml"
}

# Base64
b64encode() {
    if [ "$#" -eq 0 ]; then
        cat | base64
    else
        printf '%s' "$1" | base64
    fi
}

b64encodefile() {
    if [ "$#" -eq 0 ]; then
        echo "Filename needed."
        return 1
    else
        base64 "$1" >encoded64.txt
        echo "${1}'s content encoded in base64 and saved as encoded64.txt"
    fi
}

decode64() {
    if [ "$#" -eq 0 ]; then
        cat | base64 --decode
    else
        printf '%s' "$1" | base64 --decode
    fi
}

alias e64='b64encode'
alias ef64='b64encodefile'
alias d64='b64decode'
