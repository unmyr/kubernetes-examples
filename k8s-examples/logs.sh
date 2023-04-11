#!/bin/bash
usage() {
    cat 1>&2 <<EOF
Usage: $0 {logs|names} [-n |--namespace]
EOF
}

GETOPT_TEMP=$(getopt -o n: --long namespace: -- "$@")
eval set -- "${GETOPT_TEMP}"
unset GETOPT_TEMP

while [ $# -gt 0 ]; do
    case "$1" in
    -n|--namespace) NAMESPACE=$2; shift 2;;
    --) shift; break;;
    *)
        echo "ERROR: Unexpected option: OPTION='$1'" 1>&2
        usage
        exit 1
        ;;
    esac
done

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

SUB_COMMAND=$1
case "${SUB_COMMAND}" in
names)
    if [ -n "${NAMESPACE}" ]; then
        echo "# NAMESPACE: ${NAMESPACE}"
        for POD_NAME in $(kubectl get pods -n "${NAMESPACE}" --output=jsonpath='{.items[*].metadata.name}'); do
            (set -x; kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}')
            (set -x; kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{range .spec.initContainers[*]}{.name}{"\n"}{end}')
        done
        echo
    else
        for NAMESPACE in $(kubectl get ns --output=jsonpath='{.items[*].metadata.name}'); do
            pod_names=($(kubectl get pods -n "${NAMESPACE}" --output=jsonpath='{.items[*].metadata.name}'))
            test ${#pod_names[@]} -eq 0 && continue

            echo "# NAMESPACE: ${NAMESPACE}"
            for POD_NAME in "${pod_names[@]}"; do
                containers=($(kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}'))
                initContainers=($(kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{range .spec.initContainers[*]}{.name}{"\n"}{end}'))
                test ${#containers[@]} -eq 0 -a ${#initContainers[@]} -eq 0 && continue

                echo " - Pod: ${POD_NAME}"
                if [ ${#containers[@]} -ne 0 ]; then
                    echo "   - containers"
                    for CONTAINER_NAME in "${containers[@]}"; do
                        echo "     - ${CONTAINER_NAME}"
                    done
                fi
                if [ ${#initContainers[@]} -ne 0 ]; then
                    echo "   - initContainers"
                    for CONTAINER_NAME in "${initContainers[@]}"; do
                        echo "     - ${CONTAINER_NAME}"
                    done
                fi
                echo
            done
        done
    fi
    ;;

logs)
    echo "# Pod logs"
    for POD_NAME in $(kubectl get pods -n "${NAMESPACE}" --output=jsonpath='{.items[*].metadata.name}'); do
        for CONTAINER_NAME in $(kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{.spec.containers[*].name}'); do
            (set -x; kubectl logs -n "${NAMESPACE}" "pod/${POD_NAME}" -c "${CONTAINER_NAME}")
        done
        for CONTAINER_NAME in $(kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{range .spec.initContainers[*]}{.name}{"\n"}{end}'); do
            (set -x; kubectl logs -n "${NAMESPACE}" "pod/${POD_NAME}" -c "${CONTAINER_NAME}")
        done
    done
    ;;

*)
    usage
    ;;
esac
