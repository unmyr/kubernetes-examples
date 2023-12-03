#!/bin/bash
usage() {
    MESSAGE="$1"
    test -n "${MESSAGE}" && echo "${MESSAGE}" 1>&2
    cat 1>&2 <<EOF
usage:
$0 preview
$0 {apply|delete}
$0 {show|describe|logs}
EOF
}

NAMESPACE="unbound"
APP_NAME="unbound"

test -f ./.env && . ./.env

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
preview)
    echo "Timestamp: $(date --iso-8601=second)"
    (set -x; kubectl create -k . --dry-run=client -o yaml > .kustomization-out.yaml)
    echo "Generate: .kustomization-out.yaml"
    ;;

apply)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl create ns "${NAMESPACE:-default}" --dry-run=client -o yaml | kubectl apply -f-
    kubectl apply --server-side=true -k .

    time kubectl rollout status -n "${NAMESPACE:-default}" deployments/${APP_NAME:-unbound}
    kubectl get -n "${NAMESPACE:-default}" -l app=${APP_NAME:-unbound} cm,secrets,pods,deploy,svc -o wide
    UNBOUND_IP=$(kubectl get -n "${NAMESPACE:-default}" -l app=unbound svc -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
    cat > .env.svc <<EOF
NAMESPACE="${NAMESPACE:-default}"
APP_NAME="${APP_NAME:-unbound}"
UNBOUND_IP="${UNBOUND_IP}"
EOF
    ;;

delete)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    time kubectl delete -n "${NAMESPACE:-default}" -l app=${APP_NAME:-unbound} cm,secrets,deploy,svc
    time kubectl delete ns "${NAMESPACE:-default}"
    rm -f .env.svc
    ;;

show)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl get -n "${NAMESPACE:-default}" -l app=${APP_NAME:-unbound} cm,secrets,pods,deploy,svc,endpoints -o wide
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events']])])"
    ;;

describe)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl describe -n "${NAMESPACE:-default}" deployments/${APP_NAME:-unbound}
    kubectl describe -n "${NAMESPACE:-default}" -l app=${APP_NAME:-unbound} pods
    ;;

logs)
    echo "Timestamp: $(date --iso-8601=second)"
    for POD_NAME in $(kubectl get -n "${NAMESPACE:-default}" -l app="${APP_NAME:-unbound}" pods -o jsonpath='{.items[*].metadata.name}'); do
        (set -x; kubectl logs -n "${NAMESPACE:-default}" pod/${POD_NAME})
    done
    ;;

*)
    usage "ERROR: Unsupported subcommand : SUB-COMMAND='${SUB_COMMAND}'"
    exit 1
    ;;

esac
