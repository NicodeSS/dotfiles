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
