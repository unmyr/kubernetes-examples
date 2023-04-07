#!/bin/bash
usage() {
    cat 1>&2 <<EOF
usage: $0 {apply|delete|describe|show}
EOF
}

NAMESPACE="shell-cron-job"
APP_NAME="shell-cron-job"

SUB_COMMAND=$1

case ${SUB_COMMAND} in
apply)
    set -x
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl apply -f -
    kubectl apply -n "${NAMESPACE}" -f workload.yaml
    ;;

delete)
    set -x
    kubectl delete cronjob.batch,job.batch,pod -n "${NAMESPACE}" -l app=${APP_NAME}
    kubectl get all,cronjob.batch,job.batch,pod -n "${NAMESPACE}"
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl delete -f -
    ;;

show)
    set -x
    kubectl get all,cronjob.batch,job.batch,pod -n "${NAMESPACE}"
    ;;

describe)
    kubectl get job.batch -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read JOB_NAME; do
        (set -x; kubectl describe -n "${NAMESPACE}" "job.batch/${JOB_NAME}")
    done

    kubectl get pod -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read POD_NAME; do
        (set -x; kubectl describe -n "${NAMESPACE}" "pod/${POD_NAME}")
    done
    ;;

logs)
    kubectl get job.batch -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read JOB_NAME; do
        (set -x; kubectl logs -n "${NAMESPACE}" "job.batch/${JOB_NAME}")
    done

    kubectl get pod -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read POD_NAME; do
        (set -x; kubectl logs -n "${NAMESPACE}" "${POD_NAME}")
    done
    ;;

*)
    usage
    ;;
esac
