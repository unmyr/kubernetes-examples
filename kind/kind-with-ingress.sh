#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

usage() {
  cat 1>&2 <<EOF
Usage: $0 {create|delete}
EOF
}

CMD=$1
case $1 in
create)
    cat <<EOF | kind create cluster --config=-
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
EOF
    set -x
    kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
    kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"},{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'

    : Install MetalLb
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
    kubectl apply -f ${SCRIPT_DIR}/metallb-IPAddressPool.yaml

    : Install metrics-server
    # https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
    ;;

delete)
    (set -x; kind delete cluster --name kind)
    ;;

*)
    usage
    exit 1
    ;;
esac
