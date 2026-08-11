#!/usr/bin/env bash

set -euo pipefail

source .env

declare -A PROJECTS=(
    [reverse_proxy]="$SERVICES_PATH/reverse_proxy/docker-compose.yml"
    [forgejo]="$SERVICES_PATH/forgejo/docker-compose.yml"
    [homarr]="$SERVICES_PATH/homarr/docker-compose.yml"
    [immich]="$SERVICES_PATH/immich/docker-compose.yml"
    [jellyfin]="$SERVICES_PATH/jellyfin/docker-compose.yml"
    [kosync]="$SERVICES_PATH/kosync/docker-compose.yml"
    [miniflux]="$SERVICES_PATH/miniflux/docker-compose.yml"
    [pihole]="$SERVICES_PATH/pihole/docker-compose.yml"
    [portainer]="$SERVICES_PATH/portainer/docker-compose.yml"
    [searxng]="$SERVICES_PATH/searxng/docker-compose.yml"
)

compose_up() {

    sudo docker network create \
        --driver bridge \
        --subnet "$PROXY_NET_SUBNET" \
        --gateway "$PROXY_NET_GATEWAY" \
        proxy_net

    for project in "${!PROJECTS[@]}"; do
        [[ "$project" == "reverse_proxy" ]] && continue

        sudo docker compose \
            -f "${PROJECTS[$project]}" \
            up -d
    done

    # proxy must start last so that all hosts are available
    # otherwise it enters restart loop
    sudo docker compose -f "${PROJECTS[reverse_proxy]}" up -d
}

compose_down() {

    for project in "${!PROJECTS[@]}"; do
        [[ "$project" == "reverse_proxy" ]] && continue

        sudo docker compose \
            -f "${PROJECTS[$project]}" \
            down
    done

    sudo docker compose -f "$HOME/services/reverse_proxy/docker-compose.yml" down

    sudo docker network rm proxy_net
}

compose_restart() {
    down
    up
}

cmd="${1:-}"
shift || true

case "$cmd" in
up)
    compose_up
    ;;
down)
    compose_down
    ;;
restart)
    compose_restart
    ;;
*)
    echo "Usage: $0 {up|down|restart}"
    exit 1
    ;;
esac
