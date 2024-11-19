#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

usage() {
  cat 1>&2 <<EOF
Usage: $0 {create|delete|show}
EOF
}

type go > /dev/null 2>&1 || \
{ echo "ERROR: go is not installed."; exit 1; }
type kubectl > /dev/null 2>&1 || \
{ echo "ERROR: kubectl is not installed."; exit 1; }

KIND_CLUSTER_NAME="kind-1"
PV_NAME_DOCKER_REGISTRY="docker-registry-pv"
PV_NAME_POSTGRES="postgres-data-pv"
. .env

SUB_COMMAND=$1
case "${SUB_COMMAND}" in
reinstall-go)
    set -x
    GO_VERSION_LATEST=$(git ls-remote --tag https://go.googlesource.com/go | awk '{print $2}' | sed -e '/\(beta[0-9]*\|rc[0-9]*\|release\|weekly\)/d; s@refs/tags/@@' | sort -V | tail -1)
    test -f ${GO_VERSION_LATEST}.linux-amd64.tar.gz || {
      curl -L -O https://go.dev/dl/${GO_VERSION_LATEST}.linux-amd64.tar.gz
      sha256sum go*.tar.gz
    }
    sudo rm -rf ${GOROOT:-$HOME/go} ${GOPATH:-$HOME/go_projects}
    tar -C $HOME -xzf ${GO_VERSION_LATEST}.linux-amd64.tar.gz
    go version
    go install sigs.k8s.io/kind@v0.25.0
    ;;

create)
    MOUNT_POINT_DOCKER_REGISTRY="/var/kind/docker-registry"
    MOUNT_POINT_POSTGRES="/tmp/kind-1-postgres-data"
    mkdir -p ${MOUNT_POINT_POSTGRES}

    # https://kind.sigs.k8s.io/docs/user/private-registries/#use-a-certificate
    cat <<EOF | kind create cluster --name ${KIND_CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: ipv4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: ${MOUNT_POINT_DOCKER_REGISTRY}
    containerPath: ${MOUNT_POINT_DOCKER_REGISTRY}
  - hostPath: /etc/docker/certs.d/docker.example.internal
    containerPath: /etc/docker/certs.d/docker.example.internal
- role: worker
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0"  
  - containerPort: 443
    hostPort: 443
    listenAddress: "0.0.0.0"
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
  - hostPath: ${MOUNT_POINT_POSTGRES}
    containerPath: ${MOUNT_POINT_POSTGRES}

containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.configs."docker.example.internal".tls]
      cert_file = "/etc/docker/certs.d/docker.example.internal/ba_client.cert"
      key_file  = "/etc/docker/certs.d/docker.example.internal/ba_client.key"
EOF

    KUBE_NODENAME_CONTROL_PLANE="${KIND_CLUSTER_NAME}-control-plane"
    KUBE_NODENAME_WORKER="${KIND_CLUSTER_NAME}-worker"
    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME_DOCKER_REGISTRY}
spec:
  capacity:
    storage: 3Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ""
  local:
    path: ${MOUNT_POINT_DOCKER_REGISTRY}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
            - ${KUBE_NODENAME_CONTROL_PLANE}
EOF

    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME_POSTGRES}
spec:
  capacity:
    storage: 512Mi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ""
  local:
    path: ${MOUNT_POINT_POSTGRES}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
            - ${KUBE_NODENAME_WORKER}
EOF
    set -x
    curl -L --silent -w '%{stdout}' https://raw.githubusercontent.com/projectcontour/contour/release-1.30/examples/render/contour.yaml | \
sed -e 's/# \(cluster:\)/\1/' \
-e '/#   configure the cluster dns lookup family/d' \
-e '/#   valid options are: auto (default), v4, v6/d' \
-e 's/#   dns-lookup-family: \(v4\|v6\|auto\)/  dns-lookup-family: v4/' | \
kubectl apply -f -
    kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"},{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}' -o yaml
    set +x
    if [ -n "${PRIVATE_DNS}" ]; then
        (set -x; kubectl patch -n projectcontour deployments/contour -p "{\"spec\": {\"template\": {\"spec\": {\"dnsConfig\":{ \"nameservers\": [\"${PRIVATE_DNS}\"] } } } } }")
    fi
    (set -x; kubectl rollout restart daemonset envoy -n projectcontour)

    : Install MetalLb
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
    kubectl rollout status deployment/controller -n metallb-system
    kubectl apply -f ${SCRIPT_DIR}/metallb-IPAddressPool.yaml

    : Install metrics-server
    # https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

    : Install cert-manager
    (set -x; kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml)
    (set -x; kubectl get -n cert-manager deployment.apps,replicaset.apps,pods,service)
    (set -x; kubectl rollout status deployment -n cert-manager --timeout=90s)
    (set -x; kubectl get -n cert-manager deployment.apps,replicaset.apps,pods,service)
    : Install Service Binding
    (set -x; kubectl apply -f https://github.com/servicebinding/runtime/releases/download/v1.0.0/servicebinding-runtime-v1.0.0.yaml)
    ;;

delete)
    (set -x; kubectl delete -f https://github.com/servicebinding/runtime/releases/download/v1.0.0/servicebinding-runtime-v1.0.0.yaml)
    (set -x; kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml)
    (set -x; kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)
    (set -x; kubectl delete -f ${SCRIPT_DIR}/metallb-IPAddressPool.yaml)
    (set -x; kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml)
    (set -x; kubectl delete -f https://raw.githubusercontent.com/projectcontour/contour/release-1.30/examples/render/contour.yaml)
    while read LINE; do
        NS_AND_DEPLOY=($LINE)
        DB_NAMESPACE=${NS_AND_DEPLOY[0]}
        DB_DEPLOY_NAME=${NS_AND_DEPLOY[1]}
        (
          set -x
          kubectl delete -n "${DB_NAMESPACE}" deploy,pvc,svc -l app=postgres
        )
    done< <(
      kubectl get -A deploy -l app=${APP_NAME:-postgres} -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}'
    )
    (set -x; kubectl delete persistentvolume ${PV_NAME_POSTGRES})

    (set -x; kubectl delete persistentvolume ${PV_NAME_DOCKER_REGISTRY})
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
