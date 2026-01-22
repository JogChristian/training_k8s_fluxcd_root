#!/bin/bash

get_workdir() {
    DIRPATH=$(dirname "$0")
    cd "$DIRPATH"
    pwd
    cd - > /dev/null
}
WORKDIR=$(get_workdir)
export WORKDIR="$WORKDIR"

start() {
    set -e
    mkdir -p "$HOME/k3d/registry"
    mkdir -p "$HOME/k3d/storage/server0"
    
    k3d cluster create -c "$WORKDIR/k3d-develop-config.yaml"

    echo -e "\n\nWait for kube-system Deployments\n\n"
    kubectl rollout status deployment -n kube-system -w
}

delete() {
    	k3d cluster delete develop
}

CMDS=(k3d kubectl k9s)
for c in "${CMDS[@]}"; do
    if ! command -v "$c" &> /dev/null; then
        echo "${c} wird nicht gefunden"
        exit
    fi
done

case $1 in
    start)
        if k3d cluster list develop >/dev/null 2>&1; then
            echo Cluster is online
        else
            start "$2"
        fi
        ;;
    delete)
	delete
	;;
    stop)
	delete
	;;
    *)
        echo "$0 start | delete | stop"
        ;;
esac

