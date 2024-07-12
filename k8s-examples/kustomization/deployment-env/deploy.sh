#!/bin/bash
usage() {
    MESSAGE="$1"
    test -n "${MESSAGE}" && echo "${MESSAGE}" 1>&2
    cat <<EOF
usage: $0 {preview|apply|delete|show}
EOF
}

APP_NAME="kustomize-deploy-demo"
NAMESPACE="${NAMESPACE:-${APP_NAME}}"

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
preview)
    set -x
    kubectl kustomize ./
    ;;

apply)
    set -x
    test "${NAMESPACE}" = "default" || {
        kubectl create ns "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
    }
    kubectl apply -k ./
    kubectl get -n "${NAMESPACE}" all
    kubectl rollout status -n "${NAMESPACE}" deployment -l app.kubernetes.io/name=${APP_NAME} --timeout=10s
    set +x
    kubectl get -n "${NAMESPACE}" pods -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" | while read POD_NAME; do
        (set -x; kubectl get -n "${NAMESPACE}" pod/${POD_NAME} -o jsonpath="{.spec.containers[0].env}{'\n'}")
    done
    ;;

delete)
    NAMESPACE=$(kubectl get -A deploy -l app.kubernetes.io/name=${APP_NAME} -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{.end}' | uniq)
    test -n "${NAMESPACE}" || { echo "INFO: The deployment is already stopped." 1>&2; exit 0; }
    set -x
    kubectl delete -n "${NAMESPACE}" deploy -l app.kubernetes.io/name=${APP_NAME}
    time kubectl wait --for delete -n "${NAMESPACE}" pods -l app.kubernetes.io/name=${APP_NAME} --timeout=5s || {
        kubectl get -n "${NAMESPACE}" all -l app.kubernetes.io/name=${APP_NAME}
    }
    time kubectl delete ns "${NAMESPACE}"
    ;;

show)
    set -x
    kubectl get -A all -l app.kubernetes.io/name=${APP_NAME}
    ;;

*)
    usage "ERROR: Unsupported subcommand : SUB-COMMAND='${SUB_COMMAND}'"
    exit 1
    ;;

esac
