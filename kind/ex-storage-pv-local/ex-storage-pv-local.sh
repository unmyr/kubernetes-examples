#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_NAME=$(basename ${SCRIPT_PATH_IN} .sh)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})
WORK_DIR=$(mktemp -d -p /tmp ${SCRIPT_NAME}.XXXX)
trap 'rm -rf -- "${WORK_DIR}"' EXIT

MOUNT_POINT="/tmp/pv-test"
PV_NAME="ex-storage-pv"

KUBE_NODENAME="kind-1-control-plane"
KUBE_HOSTNAME=$(kubectl get nodes ${KUBE_NODENAME} -o jsonpath="{.metadata.labels.kubernetes\.io/hostname}")

cat > ${WORK_DIR}/ex-storage-pv-local.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME}
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

case $1 in
create)
    set -x
    docker exec ${KUBE_NODENAME} mkdir -p ${MOUNT_POINT}
    kubectl apply -f ${WORK_DIR}/ex-storage-pv-local.yaml
    ;;

apply)
    kubectl apply -f ${WORK_DIR}/ex-storage-pv-local.yaml
    ;;

delete)
    set -x
    kubectl delete persistentvolume ${PV_NAME}
    docker exec ${KUBE_NODENAME} rmdir ${MOUNT_POINT}
    ;;

show)
    set -x
    kubectl get persistentvolume ${PV_NAME}
    docker exec ${KUBE_NODENAME} df -h ${MOUNT_POINT}
    ;;
esac