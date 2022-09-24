#!/bin/bash
. .env

usage() {
    cat 1>&2 <<EOF
usage: $0 {create|delete|get}
EOF
}
if [ $# -ne 1 ]; then
    usage
    exit 1
fi

SECRET_NAME="postgres-secret"

case $1 in
create)
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
type: Opaque
data:
  POSTGRES_USER: "$(echo -n ${POSTGRES_USER} | base64)"
  POSTGRES_PASSWORD: "$(echo -n ${POSTGRES_PASSWORD} | base64)"
  ADDITIONAL_USER: "$(echo -n ${ADDITIONAL_USER} | base64)"
  ADDITIONAL_PASSWORD: "$(echo -n ${ADDITIONAL_PASSWORD} | base64)"
EOF
    ;;
delete) kubectl delete secret ${SECRET_NAME};;
get)
    (set -x; kubectl get secret ${SECRET_NAME} -o yaml)
    echo '---'
    cat <<EOF
POSTGRES_USER="$(kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)"
POSTGRES_PASSWORD="$(kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"
ADDITIONAL_USER="$(kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.ADDITIONAL_USER}' | base64 -d)"
ADDITIONAL_PASSWORD="$(kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.ADDITIONAL_PASSWORD}' | base64 -d)"
EOF
    ;;
*)
    usage
    exit 1
    ;;
esac
