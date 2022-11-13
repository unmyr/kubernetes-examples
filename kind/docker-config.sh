#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

GETOPT_TEMP=$(getopt -o n:v --long dry-run,namespace: -- "$@")
eval set -- "${GETOPT_TEMP}"
unset GETOPT_TEMP

usage() {
    cat 1>&2 <<EOF
Usage: $0 {apply|delete|show} [-n |--namespace] [--dry-run]
EOF
}

DRY_RUN="false"
NAMESPACE="default"
while [ $# -gt 0 ]; do
    case "$1" in
    -n|--namespace) NAMESPACE=$2; shift 2;;
    --dry-run) DRY_RUN="true"; shift;;
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
CMD=$1
shift 1

case $CMD in
apply)
    . ${SCRIPT_DIR}/../.env
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-secret
  namespace: ${NAMESPACE}
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "https://ghcr.io": {
          "username": "${GITHUB_USERNAME}",
          "password": "${GITHUB_API_TOKEN}"
        }
      }
    }
EOF
    kubectl patch -n ${NAMESPACE} serviceaccount default -p "{\"secrets\":[{\"name\":\"ghcr-secret\"}],\"imagePullSecrets\":[{\"name\":\"ghcr-secret\"}]}"
    ;;

delete)
    (set -x; kubectl delete -n ${NAMESPACE} serviceaccount default)
    (set -x; kubectl delete -n ${NAMESPACE} secrets ghcr-secret)
    ;;

show)
    (set -x; kubectl get -n ${NAMESPACE} secrets ghcr-secret)
    (set -x; kubectl get -n ${NAMESPACE} ServiceAccount default)
    (set -x; kubectl get -n ${NAMESPACE} ServiceAccount default -o yaml)
    ;;

esac
