#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

usage() {
  cat 1>&2 <<EOF
Usage: $0 {create|delete|show}
EOF
}

KIND_CLUSTER_NAME="kind-1"
PV_NAME="postgres-data-pv"

CMD=$1
case $1 in
create)
    MOUNT_POINT="/tmp/kind-1-postgres-data"
    mkdir -p ${MOUNT_POINT}
    cat <<EOF | kind create cluster --name ${KIND_CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30081
    hostPort: 30081
    protocol: TCP
  extraMounts:
  - hostPath: ${MOUNT_POINT}
    containerPath: ${MOUNT_POINT}
EOF
    set -x

    KUBE_NODENAME="${KIND_CLUSTER_NAME}-control-plane"
    kubectl apply -f <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME}
spec:
  capacity:
    storage: 512Mi
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
            - ${KUBE_NODENAME}
EOF
    kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
    kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"},{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'

    : Install MetalLb
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
    while true; do
        if [ -n "$(kubectl get pods -n metallb-system 2> /dev/null)" ]; then
            break
        fi
        sleep 1
    done
    kubectl wait pods -n metallb-system -l component=controller --for condition=Ready --timeout=90s
    kubectl wait pods -n metallb-system -l component=speaker --for condition=Ready --timeout=90s
    kubectl apply -f ${SCRIPT_DIR}/metallb-IPAddressPool.yaml

    : Install metrics-server
    # https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

    : Install cert-manager
    (set -x; kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml)
    while true; do
        if [ -n "$(kubectl get pods -n cert-manager -l app.kubernetes.io/component=webhook 2> /dev/null)" ]; then
            break
        fi
        sleep 1
    done
    (set -x; kubectl wait pods -n cert-manager -l app.kubernetes.io/component=webhook --for condition=Ready --timeout=90s)
    (set -x; kubectl get deployment.apps -n cert-manager)
    (set -x; kubectl get pods -n cert-manager)
    (set -x; kubectl rollout status deployment -n cert-manager -l component=controller --timeout=90s)
    (set -x; kubectl rollout status deployment -n cert-manager -l component=webhook --timeout=90s)
    : Install Service Binding
    (set -x; kubectl apply -f https://github.com/servicebinding/runtime/releases/download/v0.2.0/servicebinding-runtime-v0.2.0.yaml)
    ;;

delete)
    (set -x; kubectl delete persistentvolume ${PV_NAME})
    (set -x; kind delete cluster --name ${KIND_CLUSTER_NAME})
    ;;

show)
    (set -x; kind get clusters)
    (set -x; kubectl get nodes)
    (set -x; kubectl cluster-info --context kind-${KIND_CLUSTER_NAME})
    ;;

*)
    usage
    exit 1
    ;;
esac
