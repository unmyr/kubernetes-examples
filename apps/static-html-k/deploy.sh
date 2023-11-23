#!/bin/bash
NAMESPACE="static-html-k"
APP_NAME="static-html-app"

test -f ./.env && . ./.env

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
apply)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl create ns "${NAMESPACE:-default}" --dry-run=client -o yaml | kubectl apply -f-
    kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl apply -f -

    kubectl rollout status -n "${NAMESPACE:-default}" deployments/${APP_NAME}
    kubectl get -n "${NAMESPACE:-default}" -l app=${APP_NAME} cm,pods,deploy,svc -o wide
    ;;

delete)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    # (set -x; kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl delete -f -)
    kubectl delete -n "${NAMESPACE:-default}" -l app=${APP_NAME} cm,deploy,svc
    kubectl delete ns "${NAMESPACE:-default}"
    ;;

show)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl get -n "${NAMESPACE:-default}" -l app=${APP_NAME} cm,pods,deploy,svc,endpoints -o wide
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events']])])"
    ;;

describe)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl describe -n "${NAMESPACE:-default}" deployments/${APP_NAME}
    kubectl describe -n "${NAMESPACE:-default}" -l app=${APP_NAME} pods
    ;;

logs)
    set -x
    kubectl logs -n "${NAMESPACE:-default}" deployments/${APP_NAME}
    ;;

esac