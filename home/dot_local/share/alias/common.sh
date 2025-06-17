# General
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
    mkdir -p "$1" && cd "$1"
}

# Function to display the current date and time in a human-readable format
datetime() {
    date +"%Y-%m-%d %H:%M:%S"
}
# Function to display the current working directory
pwd() {
    echo "当前工作目录: $(realpath .)"
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
# Function to check if a command exists
command_exists() {
    type "$1" >/dev/null 2>&1
}
# Function to install a package using apt-get
install_pkg() {
    if [ -z "$1" ]; then
        echo "用法: install_pkg <包名>"
        return 1
    fi
    if type apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "$1"
    elif type yum >/dev/null 2>&1; then
        sudo yum install -y "$1"
    else
        echo "错误：不支持的包管理器。" >&2
        return 1
    fi
}

# Find & grep
alias ffd='find . -type d -name'
alias ff='find . -type f -name'
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
export EDITOR='nvim'
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
alias rsync-copy='rsync -avz --progress -h'
alias rsync-move='rsync -avz --progress -h --remove-source-files'
alias rsync-update='rsync -avzu --progress -h'
alias rsync-sync='rsync -avzu --delete --progress -h'

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

# ----- Docker -----
# alias d='docker'  # Docker command
alias dbl='docker build' # Build a Docker image

dex() {
    docker exec -it "$1" "${2:-bash}"
}

dnames() {
    for ID in $(docker ps | awk '{print $1}' | grep -v 'CONTAINER'); do
        docker inspect "$ID" | grep Name | head -1 | awk '{print $2}' | sed 's/,//g' | sed 's%/%%g' | sed 's/"//g'
    done
}

dip() {
    echo 'IP addresses of all named running containers'
    OUT=""
    for DOC in $(dnames); do
        IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$DOC")
        OUT="${OUT}${DOC}\t${IP}\n"
    done
    echo -e "$OUT" | column -t
    unset OUT
}

drun() {
    docker run -it "$1" "$2"
}

dsr() {
    docker stop "$1"
    docker rm "$1"
}

drmc() {
    docker rm "$(docker ps --all -q -f status=exited)"
}

drmid() {
    imgs=$(docker images -q -f dangling=true)
    if [ -n "$imgs" ]; then
        docker rmi "$imgs"
    else
        echo "No dangling images."
    fi
}

alias di='docker inspect'
alias diprune='docker image prune' # Remove unused service images
alias dirm='docker image rm'       # Remove a Docker image
alias dirmf='docker image rm -f'   # Force remove a Docker image

alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'          # Remove all stopped containers and unused images
alias dps='docker ps'                                # List running containers
alias dpsa='docker ps -a'                            # List all containers
alias dst='docker stop'                              # Stop a running container
alias dsta='docker stop $(docker ps -aq)'            # Stop all running containers
alias dsts='docker stats'                            # Display resource usage statistics for containers
alias dtop='docker top'                              # Display running processes in a container
alias dvi='docker volume inspect'                    # Docker volume command
alias dvls='docker volume ls'                        # List Docker volumes
alias dvprune='docker volume prune'                  # Remove unused Docker volumes
alias dxc='docker exec -it'                          # Execute a command in a running container
alias dxcsh='docker exec -it $(docker ps -q) sh'     # Execute a shell in a running container
alias dxcbash='docker exec -it $(docker ps -q) bash' # Execute a bash shell in a running container

# ------- Docker Compose -----
alias dc='docker compose'
alias dcb='docker compose build'                # Build or rebuild services
alias dcc='docker compose config'               # Validate and view the compose file
alias dcd='docker compose down'                 # Stop and remove services
alias dce='docker compose exec'                 # Execute a command in a running service
alias dch='docker compose help'                 # Show help for Docker Compose commands
alias dci='docker compose images'               # List service images
alias dck='docker compose kill'                 # Kill services
alias dcl='docker compose logs'                 # View logs of services
alias dclf='docker compose logs -f'             # Follow logs of services
alias dclft='docker compose logs -f --tail=100' # Follow logs of services with last 100 lines
alias dcps='docker compose ps'                  # List containers managed by Docker Compose
alias dcpull='docker compose pull'              # Pull service images
alias dcr='docker compose restart'              # Restart services
alias 'dcrmF'='docker compose rm -f'            # Remove stopped services
# Run a one-off command in a service
dcrun() {
    docker compose run $@
}
alias dcs='docker compose start'          # Start services
alias dcstop='docker compose stop'        # Stop services
alias dct='docker compose top'            # Display running processes in services
alias dcu='docker compose up -d'          # Start services in detached mode
alias dcub='docker compose up -d --build' # Start services in detached mode with build
alias dcup='docker compose up'            # Start services in the foreground
alias dcupb='docker compose up --build'   # Start services with build

# Function to edit the docker-compose file in the current directory
dco() {
    if [ -f "docker-compose.yaml" ]; then
        $EDITOR docker-compose.yaml
    elif [ -f "docker-compose.yml" ]; then
        $EDITOR docker-compose.yml
    else
        echo "Error: docker-compose file not found." >&2
        return 1
    fi
}

#  ----- Git -----

git_current_branch() {
    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    # Get the current branch name
    git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "HEAD"
}

git_develop_branch() {
    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    # Check for common develop branch names
    for branch in dev devel develop development; do
        if git show-ref -q --verify "refs/heads/$branch"; then
            echo "$branch"
            return 0
        fi
    done

    # Default to 'develop' and return error
    echo "develop"
    return 1
}

git_main_branch() {
    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    # Check for common main branch names
    # refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,
    # stable,master}
    for ref in "refs/heads/main" "refs/heads/trunk" "refs/heads/mainline" \
        "refs/heads/default" "refs/heads/stable" "refs/heads/master" \
        "refs/remotes/origin/main" "refs/remotes/origin/trunk" \
        "refs/remotes/origin/mainline" "refs/remotes/origin/default" \
        "refs/remotes/origin/stable" "refs/remotes/origin/master" \
        "refs/remotes/upstream/main" "refs/remotes/upstream/trunk" \
        "refs/remotes/upstream/mainline" "refs/remotes/upstream/default" \
        "refs/remotes/upstream/stable" "refs/remotes/upstream/master"; do
        if git show-ref -q --verify "$ref"; then
            # Extract basename of ref (e.g., 'main' from 'refs/heads/main')
            echo "$ref" | sed 's|.*/||'
            return 0
        fi
    done

    # Default to 'master' and return error
    echo "master"
    return 1
}

grename() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 old_branch new_branch"
        return 1
    fi

    # Rename branch locally
    git branch -m "$1" "$2"
    # Rename branch in origin remote
    if git push origin ":$1"; then
        git push --set-upstream origin "$2"
    fi
}

alias g='git' # Git command

alias grt='cd "$(git rev-parse --show-toplevel || echo .)"' # Change to the root directory of the current Git repository

ggpnp() {
    if [ "$#" -eq 0 ]; then
        ggl && ggp
    else
        ggl "${*}" && ggp "${*}"
    fi
} # Function to run `ggl` (git pull) and `ggp` (git push) in sequence

# add - 'ga'
alias ga='git add'                                                                                                                         # Add files to staging area
alias gaa='git add --all'                                                                                                                  # Add all files to staging area
alias gapa='git add --patch'                                                                                                               # Add changes interactively
alias gau='git add --update'                                                                                                               # Add updated files to staging area
alias gav='git add --verbose'                                                                                                              # Add files with verbose output
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"' # Add all changes and commit with a WIP message, skipping CI

# am - 'gam'
alias gam='git am'                         # Apply a patch from an email
alias gama='git am --abort'                # Abort an am operation
alias gamc='git am --continue'             # Continue an am operation
alias gamscp='git am --show-current-patch' # Show the current patch in an am operation
alias gams='git am --skip'                 # Skip the current patch in an am operation

# apply - 'gap'
alias gap='git apply'         # Apply a patch
alias gapt='git apply --3way' # Apply a patch with three-way merge

# bisect - 'gbs'
alias gbs='git bisect'        # Start a bisect session
alias gbsb='git bisect bad'   # Mark the current commit as bad
alias gbsg='git bisect good'  # Mark the current commit as good
alias gbsn='git bisect new'   # Mark the current commit as new
alias gbso='git bisect old'   # Mark the current commit as old
alias gbsr='git bisect reset' # Reset the bisect session
alias gbss='git bisect start' # Start a new bisect session

# blame - 'gbl'
alias gbl='git blame'                    # Show who changed each line of a file
alias gbllp='git blame --line-porcelain' # Show detailed blame information
alias gblln='git blame --line-number'    # Show line numbers in blame output
alias gblp='git blame --porcelain'       # Show blame information in a machine-readable format

# branch - 'gb'
alias gb='git branch'                   # List branches
alias gba='git branch --all'            # List all branches, including remote
alias gbd='git branch --delete'         # Delete a branch
alias gbD='git branch --delete --force' # Force delete a branch
gbda() {
    git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
} # Delete all branches that have been merged, excluding main and develop branches
gbds() {
    default_branch=""
    # Try git_main_branch first
    if main_branch=$(git_main_branch); then
        default_branch="$main_branch"
    # Fallback to git_develop_branch
    elif dev_branch=$(git_develop_branch); then
        default_branch="$dev_branch"
    else
        echo "Error: No main or develop branch found" >&2
        return 1
    fi

    # Iterate over local branches
    git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r branch; do
        # Skip the default branch
        [ "$branch" = "$default_branch" ] && continue

        # Get merge base
        merge_base=$(git merge-base "$default_branch" "$branch")
        if [ -z "$merge_base" ]; then
            echo "Warning: Cannot find merge base for $branch, skipping" >&2
            continue
        fi

        # Check if branch is fully merged
        # Create a temporary commit to compare against
        temp_commit=$(git commit-tree "$(git rev-parse "$branch^{tree}")" -p "$merge_base" -m "_")
        if git cherry "$default_branch" "$temp_commit" | grep -q '^-'; then
            git branch -D "$branch"
        fi
    done
}
alias gbg='LANG=C git branch -vv | grep ": gone\]"  # List branches that have been removed from the remote'
alias gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '"'"'{print $1}'"'"' | xargs git branch -d' # Delete branches that have been removed from the remote
alias gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '"'"'{print $1}'"'"' | xargs git branch -D' # Force delete branches that have been removed from the remote
alias gbm='git branch --move'                                                                                                # Rename a branch
alias gbnm='git branch --no-merged'                                                                                          # List branches that have not been merged
alias gbr='git branch --remote'                                                                                              # List remote branches
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'                                                      # Set the upstream branch for the current branch

# checkout - 'gc'
alias gco='git checkout'                       # Checkout a branch or commit
alias gcb='git checkout -b'                    # Create and checkout a new branch
alias gcB='git checkout -B'                    # Create or reset a branch to a specific commit
alias gcd='git checkout $(git_develop_branch)' # Checkout the development branch
alias gcm='git checkout $(git_main_branch)'    # Checkout the main branch
alias gcor='git checkout --recurse-submodules' # Checkout a branch and update submodules

# cherry-pick - 'gcp'
alias gcp='git cherry-pick'            # Apply changes from a commit
alias gcpa='git cherry-pick --abort'   # Abort a cherry-pick operation
alias gcpc='git cherry-pick--continue' # Continue a cherry-pick operation

# clean
alias gclean='git clean --interactive -d' # Clean untracked files interactively

# clone - 'gcl'
alias gcl='git clone --recursive-submodules'                                                        # Clone a repository with submodules
alias gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules' # Clone a repository with shallow submodules and no blobs

gccd() {
    # Extract the last argument
    last_arg=""
    for arg in "$@"; do
        last_arg="$arg"
    done

    # Try to extract repo URL from arguments (basic matching for common Git URL formats)
    repo=""
    for arg in "$@"; do
        case "$arg" in
        ssh://* | git://* | ftp://* | ftps://* | http://* | https://* | *@*:*/*.git | *@*:*/*.git/)
            repo="$arg"
            break
            ;;
        esac
    done
    # Fallback to last argument if no clear repo URL found
    [ -z "$repo" ] && repo="$last_arg"

    # Run git clone with all arguments
    git clone --recurse-submodules "$@" || return 1

    # Determine the target directory
    if [ -d "$last_arg" ]; then
        # Last argument is a directory, cd into it
        cd "$last_arg" || return 1
    else
        # Extract the directory name from the repo URL (remove .git suffix and take basename)
        dir_name=$(echo "$repo" | sed -e 's|/$||' -e 's|.git$||' -e 's|.*/||')
        # Remove trailing /# if present (handles URLs like repo.git/#)
        dir_name=$(echo "$dir_name" | sed -e 's|/#$||')
        [ -n "$dir_name" ] && cd "$dir_name" || return 1
    fi
} # Clone a Git repository with submodules and change into the cloned directory

# commit - 'gc'
alias gc='git commit --verbose'                                        # Commit changes with verbose output
alias gcF='git commit --verbose --amend'                               # Amend the last commit with verbose output
alias gca='git commit --verbose --all'                                 # Commit all changes
alias gcaF='git commit --verbose --all --amend'                        # Amend the last commit with all changes
alias gcam='git commit --all --message'                                # Commit all changes with a message
alias gcanF='git commit --verbose --all --no-edit --amend'             # Amend the last commit with all changes without editing the commit message
alias gcansF='git commit --verbose --all --no-edit --signoff --amend'  # Amend the last commit with all changes, no edit, and signoff
alias gcannF='git commit --verbose --all --date=now --no-edit --amend' # Amend the last commit with all changes, no edit, and set the date to now
alias gcas='git commit --all --signoff'                                # Commit all changes with a signoff
alias gcasm='git commit --all --signoff --message'                     # Commit all changes with a signoff and message
alias gcm='git commit --message'                                       # Commit with a message
alias gcsm='git commit --signoff --message'                            # Commit with a signoff and message
alias gcn='git commit --verbose --no-edit'                             # Commit changes without editing the commit message
alias gcnF='git commit --verbose --no-edit --amend'                    # Amend the last commit without editing the commit message
alias gcs='git commit -S'                                              # Commit with GPG signing
alias gcss='git commit -S --signoff'                                   # Commit with GPG signing and signoff
alias gcssm='git commit -S --signoff --message'                        # Commit with GPG signing, signoff, and message
alias gcfu='git commit --fixup'                                        # Create a fixup commit for the last commit

# config
alias gcf='git config' # Git configuration command

# describe
alias gdct='git describe --tags $(git rev-parse --tags --max-count=1)' # Describe the latest tag

# diff
alias gd='git diff'                        # Show differences
alias gdca='git diff --cached'             # Show changes staged for commit
alias gdcw='git diff --cached --word-diff' # Show changes staged for commit with word diff
alias gds='git diff --staged'              # Show staged changes
alias gdw='git diff --word-diff'           # Show staged changes with word diff
gdv() {
    git diff -w "$@" | view -
}
alias gdup='git diff @{upstream}' # Show differences between the current branch and its upstream branch
gdnolock() {
    git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}

# diff-tree
alias gdt='git diff-tree --no-commit-id --name-only -r' # Show differences in a tree structure

# fetch
alias gf='git fetch'                       # Fetch changes from remote
alias gfa='git fetch --all --tags --prune' # Fetch all changes from all remotes, including tags, and prune deleted branches
alias gfp='git fetch origin'               # Fetch changes from the origin remote

# gui
alias gg='git gui citool'          # Open the Git GUI tool
alias gga='git gui citool --amend' # Open the Git GUI tool to amend the last commit

# help
alias ghh='git help' # Show Git help

# log
alias glg='git log --stat'                                                                                                        # Show commit history with statistics
alias glgp='git log --stat --patch'                                                                                               # Show commit history with statistics and patches
alias glgg='git log --graph'                                                                                                      # Show commit history in a graph format
alias glgga='git log --graph --decorate --all'                                                                                    # Show commit history in a graph format with decorations for all branches
alias glgm='git log --graph --max-count=10'                                                                                       # Show the last 10 commits in a graph format
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short' # Show commit history in a graph format with short date
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'               # Show commit history in a graph format with date
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'        # Show commit history in a graph format with relative date for all branches
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'       #  Show commit history in a graph format with relative date and statistics
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'               # Show commit history in a graph format with relative date
alias glo='git log --oneline --decorate'                                                                                          # Show commit history in a one-line format with decorations
alias glog='git log --oneline --decorate --graph'                                                                                 # Show commit history in a one-line format with decorations and graph
alias gloga='git log --oneline --decorate --graph --all'                                                                          # Show commit history in a one-line format with decorations and graph for all branches
_git_log_prettily() {
    if [ -n "$1" ]; then
        git log --pretty="$1"
    fi
}
alias glp='_git_log_prettily'

# ls-files
alias gignored='git ls-files -v | grep "^[[:lower:]]"' # List ignored files in the repository
alias gfg='git ls-files | grep'                        # List files in the repository and filter with grep

# merge
alias gm='git merge'                                     # Merge changes from one branch into another
alias gma='git merge --abort'                            # Abort a merge operation
alias gmc='git merge --continue'                         # Continue a merge operation
alias gms="git merge --squash"                           # Squash merge changes from one branch into another
alias gmff="git merge --ff-only"                         # Fast-forward merge changes from one branch into another
alias gmom='git merge origin/$(git_main_branch)'         # Merge changes from the main branch of the origin remote
alias gmum='git merge upstream/$(git_main_branch)'       # Merge changes from the main branch of the upstream remote
alias gmtl='git mergetool --no-prompt'                   # Use the default merge tool without prompting
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff' # Use vimdiff as the merge tool without prompting

# pull
alias gl='git pull'                                                      # Pull changes from the remote repository
alias glr='git pull --rebase'                                            # Pull changes from the remote repository and rebase the current branch
alias glrv='git pull --rebase -v'                                        # Pull changes from the remote repository and rebase the current branch with verbose output
alias glra='git pull --rebase --autostash'                               # Pull changes from the remote repository, rebase the current branch, and automatically stash local changes
alias glrav='git pull --rebase --autostash -v'                           # Pull changes from the remote repository, rebase the current branch, and automatically stash local changes with verbose output
alias glrom='git pull --rebase origin $(git_main_branch)'                # Pull changes from the main branch of the origin remote and rebase the current branch
alias glromi='git pull --rebase=interactive origin $(git_main_branch)'   # Pull changes from the main branch of the origin remote and rebase the current branch interactively
alias glrum='git pull --rebase upstream $(git_main_branch)'              # Pull changes from the main branch of the upstream remote and rebase the current branch
alias glrumi='git pull --rebase=interactive upstream $(git_main_branch)' # Pull changes from the main branch of the upstream remote and rebase the current branch interactively
alias ggpull='git pull origin "$(git_current_branch)"'                   # Pull changes from the remote repository for the current branch
alias gluc='git pull upstream $(git_current_branch)'                     # Pull changes from the upstream remote for the current branch
alias glum='git pull upstream $(git_main_branch)'                        # Pull changes from the upstream remote for the current branch or main branch

ggu() {
    if [ "$#" -ne 1 ]; then
        b=$(git rev-parse --abbrev-ref HEAD)
    fi
    git pull --rebase origin "${b:=$1}"
} # Pull changes from the remote repository and rebase the current branch onto the upstream branch

ggl() {
    if [ "$#" -ne 0 ] && [ "$#" -ne 1 ]; then
        git pull origin "$@"
    else
        if [ "$#" -eq 0 ]; then
            b=$(git rev-parse --abbrev-ref HEAD)
        fi
        git pull origin "${b:=$1}"
    fi
} # Pull changes from the remote repository for the current branch or specified branch

# push
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf!='git push --force'                                                                              # Force push changes to remote
alias gpf='git push --force-with-lease --force-if-includes'                                                # Force push changes to remote with lease and force if includes
alias gpsup='git push --set-upstream origin $(git_current_branch)'                                         # Set the upstream branch for the current branch and push changes
alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes' # Set the upstream branch for the current branch and force push changes with lease
alias gpv='git push --verbose'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias ggpush='git push origin "$(git_current_branch)"'
alias gpu='git push upstream'

ggf() {
    if [ "$#" -ne 1 ]; then
        b=$(git rev-parse --abbrev-ref HEAD)
    fi
    git push --force origin "${b:=$1}"
}

ggfl() {
    if [ "$#" -ne 1 ]; then
        b=$(git rev-parse --abbrev-ref HEAD)
    fi
    git push --force-with-lease origin "${b:=$1}"
}

ggp() {
    if [ "$#" -ne 0 ] && [ "$#" -ne 1 ]; then
        git push origin "$@"
    else
        if [ "$#" -eq 0 ]; then
            b=$(git rev-parse --abbrev-ref HEAD)
        fi
        git push origin "${b:=$1}"
    fi
}

# rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grbd='git rebase $(git_develop_branch)'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbum='git rebase upstream/$(git_main_branch)'

# reflog
alias grf='git reflog'

# remote
alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grmv='git remote rename'
alias grset='git remote set-url'
alias grup='git remote update'

# reset
alias grh='git reset'
alias gru='git reset --'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias gpristine='git reset --hard && git clean --force -dfx'
alias gwipe='git reset --hard && git clean --force -df'
alias groh='git reset origin/$(git_current_branch) --hard'

# restore - 'grs'
alias grs='git restore'           # Restore files in the working directory
alias grss='git restore --source' # Restore changes from a specific source
alias grst='git restore --staged' # Restore changes from the staging area

# rev-list
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1' # Undo the last commit if it is a WIP commit

# revert - 'grev'
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'

# rm - 'grm'
alias grm='git rm'
alias grmc='git rm --cached'

# shortlog
alias gcount='git shortlog --summary --numbered'

# show - 'gsh'
alias gsh='git show'
alias gshps='git show --pretty=short --show-signature'

# stash - 'gst'
alias gstall='git stash --all'
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gstu='git stash push --include-untracked'

# status - 'gss'
alias gss='git status'
alias gsss='git status --short'
alias gssb='git status --short --branch'

# submodule - 'gsm'
alias gsm='git submodule'
alias gsmi='git submodule init'
alias gsmu='git submodule update'

# svn - 'gsv'
alias gsv='git svn'
alias gsvd='git svn dcommit'
alias gsvr='git svn rebase'

# switch - 'gsw'
alias gsw='git switch'
alias gswc='git switch --create'
alias gswd='git switch $(git_develop_branch)'
alias gswm='git switch $(git_main_branch)'

# tag - 'gt'
alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'

gtl() {
    git tag --sort=-v:refname -n --list "${1}*"
}

# whatchanged - 'gwc'
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'

# worktree - 'gwt'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# special
alias gignore='git update-index --assume-unchanged'
alias gunignore='git update-index --no-assume-unchanged'
