#!/bin/bash
usage() {
    MESSAGE="$1"
    test -n "${MESSAGE}" && echo "${MESSAGE}" 1>&2
    cat <<EOF
usage: $0 {preview|apply|delete|show}
EOF
}

PART_OF_APP="kustomize-deploy-demo"
NAMESPACE="kustomize-deploy-demo"

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
preview)
    set -x
    kubectl kustomize ./
    ;;

apply)
    set -x
    kubectl create ns "${NAMESPACE:-default}" --dry-run=client -o yaml | kubectl apply -f -
    kubectl kustomize ./ | kubectl apply -f -
    kubectl get -n "${NAMESPACE:-default}" all
    # kubectl wait -n "${NAMESPACE:-default}" --for=condition=Available deployments --selector=app.kubernetes.io/part-of=${PART_OF_APP} --timeout=10s
    kubectl rollout status -n "${NAMESPACE:-default}" deployment -l app.kubernetes.io/part-of=${PART_OF_APP} --timeout=10s
    set +x
    kubectl get -n "${NAMESPACE:-default}" pods -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" | while read POD_NAME; do
        (set -x; kubectl get -n "${NAMESPACE:-default}" pod/${POD_NAME} -o jsonpath="{.spec.containers[0].env}{'\n'}")
    done
    ;;

delete)
    set -x
    kubectl kustomize ./ | kubectl delete -f -
    kubectl delete ns "${NAMESPACE:-default}"
    ;;

show)
    set -x
    kubectl get -n "${NAMESPACE:-default}" all
    ;;

*)
    usage "ERROR: Unsupported subcommand : SUB-COMMAND='${SUB_COMMAND}'"
    exit 1
    ;;

esac
