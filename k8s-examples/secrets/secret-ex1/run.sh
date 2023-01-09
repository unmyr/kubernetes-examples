#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_NAME=$(basename ${SCRIPT_PATH_IN} .sh)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})
WORK_DIR=$(mktemp -d -p /tmp ${SCRIPT_NAME}.XXXX)
trap 'rm -rf -- "${WORK_DIR}"' EXIT

usage() {
    cat 1>&2 <<EOF
usage: $0 {create|delete|show}
EOF
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi
CMD=$1
NAMESPACE="secret-ex1"
SECRET_NAME="secret-ex1"
JOB_NAME="test-job"

case $CMD in
create)
    (
     set -x;
     kubectl create ns ${NAMESPACE}
     printf "apple\nbanana\ncherry\n" > ${WORK_DIR}/fruits.txt
     kubectl create secret generic -n ${NAMESPACE} ${SECRET_NAME} --from-file=${WORK_DIR}/fruits.txt
     kubectl apply -f ${SCRIPT_DIR}/busybox.yaml -n ${NAMESPACE}
    )
    ;;

delete)
    (set -x; kubectl delete -f ${SCRIPT_DIR}/busybox.yaml -n ${NAMESPACE})
    (set -x; kubectl delete secret -n ${NAMESPACE} ${SECRET_NAME})
    (set -x; kubectl delete ns ${NAMESPACE})
    ;;

show)
    (set -x; kubectl get secret -n ${NAMESPACE} ${SECRET_NAME} -o jsonpath="{.data['fruits\.txt']}" | base64 -d)
    (set -x; kubectl get pods -n ${NAMESPACE})
    kubectl get pods --selector=job-name=${JOB_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' -n ${NAMESPACE} | while read POD_NAME; do
        (set -x; kubectl logs -n ${NAMESPACE} ${POD_NAME})
    done
    ;;

esac
