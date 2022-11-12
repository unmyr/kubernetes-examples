#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

. ${SCRIPT_DIR}/../.env

CMD=$1
NAMESPACE="default"

case $CMD in
    apply)
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

show)
    (set -x; kubectl get -n ${NAMESPACE} secrets ghcr-secret)
    (set -x; kubectl get -n ${NAMESPACE} serviceaccount default)
    ;;

delete)
    (set -x; kubectl delete -n ${NAMESPACE} serviceaccount default)
    (set -x; kubectl delete -n ${NAMESPACE} secrets ghcr-secret)
    ;;
esac
