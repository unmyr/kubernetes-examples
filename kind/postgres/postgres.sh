#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_NAME=$(basename ${SCRIPT_PATH_IN} .sh)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})
WORK_DIR=$(mktemp -d -p /tmp ${SCRIPT_NAME}.XXXX)
trap 'rm -rf -- "${WORK_DIR}"' EXIT

usage() {
    cat 1>&2 <<EOF
usage: $0 {create|delete|get}
EOF
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi
CMD=$1
NAMESPACE="postgres"
MOUNT_POINT="/tmp/pv-postgres"
PV_NAME="postgres-local-pv"

KUBE_NODENAME="kind-1-control-plane"
KUBE_HOSTNAME=$(kubectl get nodes ${KUBE_NODENAME} -o jsonpath="{.metadata.labels.kubernetes\.io/hostname}")
PV_MANIFEST_PATH="${WORK_DIR}/${PV_NAME}.yaml"

SECRET_NAME="postgres-secret"

cat > ${PV_MANIFEST_PATH} <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME}
  labels:
    app: postgres
spec:
  capacity:
    storage: 256Mi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ""
  local:
    path: ${MOUNT_POINT}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
            - ${KUBE_HOSTNAME}
EOF

case $CMD in
create)
    (set -x; kubectl create ns ${NAMESPACE})
    (set -x; docker exec ${KUBE_NODENAME} mkdir -p ${MOUNT_POINT})
    (set -x; kubectl apply -n ${NAMESPACE} -f ${PV_MANIFEST_PATH})
    . .env
    set -x
    kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  labels:
    app: postgres
type: Opaque
data:
  POSTGRES_USER: "$(echo -n ${POSTGRES_USER} | base64)"
  POSTGRES_PASSWORD: "$(echo -n ${POSTGRES_PASSWORD} | base64)"
  ADDITIONAL_USER: "$(echo -n ${ADDITIONAL_USER} | base64)"
  ADDITIONAL_PASSWORD: "$(echo -n ${ADDITIONAL_PASSWORD} | base64)"
EOF
    kubectl apply -n ${NAMESPACE} -f postgres.pod.yaml
    ;;

delete)
    set -x
    kubectl -n ${NAMESPACE} delete -f postgres.pod.yaml
    kubectl -n ${NAMESPACE} delete secret ${SECRET_NAME}
    kubectl delete persistentvolume ${PV_NAME}
    docker exec ${KUBE_NODENAME} rm -fR ${MOUNT_POINT}
    kubectl delete ns ${NAMESPACE}
    ;;

show)
    (set -x; kubectl -n ${NAMESPACE} get persistentvolume ${PV_NAME})
    (set -x; docker exec ${KUBE_NODENAME} df -h ${MOUNT_POINT})
    # (set -x; kubectl -n ${NAMESPACE} -l app=postgres get secret -o yaml)
    (set -x; kubectl -n ${NAMESPACE} get secret ${SECRET_NAME} -o yaml)
    echo '---'
    . .env
    cat <<EOF
POSTGRES_USER="$(kubectl -n ${NAMESPACE} get secret ${SECRET_NAME} -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)"
POSTGRES_PASSWORD="$(kubectl -n ${NAMESPACE} get secret ${SECRET_NAME} -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"
ADDITIONAL_USER="$(kubectl -n ${NAMESPACE} get secret ${SECRET_NAME} -o jsonpath='{.data.ADDITIONAL_USER}' | base64 -d)"
ADDITIONAL_PASSWORD="$(kubectl -n ${NAMESPACE} get secret ${SECRET_NAME} -o jsonpath='{.data.ADDITIONAL_PASSWORD}' | base64 -d)"
EOF
    (set -x; kubectl -n ${NAMESPACE} -l app=postgres get configmap,pods)
	(set -x; kubectl -n ${NAMESPACE} describe pod postgres-pod)
    ;;

logs)
	(set -x; kubectl -n ${NAMESPACE} logs postgres-pod)
    ;;

*)
    usage
    exit 1
    ;;
esac
