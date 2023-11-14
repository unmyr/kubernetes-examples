#!/bin/bash
usage() {
    MESSAGE="$1"
    test -n "${MESSAGE}" && echo "${MESSAGE}" 1>&2
    cat <<EOF
usage:
$0 apply [--dry-run]
$0 delete
$0 {describe|logs|show}
$0 {test-cluster-ip|test-external}
$0 {show-registry}
EOF
}

SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_NAME=$(basename ${SCRIPT_PATH_IN} .sh)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

GETOPT_TEMP=$(getopt -o n:v --long dry-run,namespace: -- "$@")
eval set -- "${GETOPT_TEMP}"
unset GETOPT_TEMP

APP_NAME="greet-go-pvt-repo"
DRY_RUN=false
NAMESPACE="greet-go"
POD_NAME="greet-go-pod"
SERVICE_NAME="greet-go-service"

. ../.env

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

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
apply)
    test -z "${PRIVATE_NS}" && { echo "ERROR: A required environment variable is missing. : NAME='PRIVATE_NS'"; exit 1;}
    test -z "${REGISTRY_FQDN_AND_PORT}" && { echo "ERROR: A required environment variable is missing. : NAME='REGISTRY_FQDN_AND_PORT'"; exit 1;}
    cat > .dockerconfigjson <<EOF
{ "auths": { "${REGISTRY_FQDN_AND_PORT}": { "auth": "$(echo -n "alice:$(cat ../.pass-alice)" | base64)" } } }
EOF

    cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonLabels:
  app: ${APP_NAME}
namespace: ${NAMESPACE}

resources:
- pod.yaml
- service.yaml

secretGenerator:
- name: reg-cred
  type: kubernetes.io/dockerconfigjson
  files:
  - .dockerconfigjson

patches:
- target:
    version: v1
    kind: Pod
    namespace: ${NAMESPACE}
    name: ${POD_NAME}
  patch: |-
    - op: replace
      path: /spec/containers/0/image
      value: ${REGISTRY_FQDN_AND_PORT}/greet-go:0.1
- patch: |-
    apiVersion: v1
    kind: Pod
    metadata:
      namespace: ${NAMESPACE}
      name: ${POD_NAME}
    spec:
      dnsPolicy: None
      dnsConfig:
        nameservers:
        - ${PRIVATE_NS}
EOF
    if [ ${DRY_RUN} = true ]; then
        set -x
        kubectl kustomize ./ | tee .kustomization-out.yaml
    else
        set -x
        kubectl create ns "${NAMESPACE:-default}" --dry-run=client -o yaml | kubectl apply -f -
        kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl apply -f -
        kubectl wait -n "${NAMESPACE:-default}" --for=condition=Ready --timeout=10s pod/${POD_NAME}
        kubectl describe pods -n "${NAMESPACE:-default}"
        kubectl get pods -n "${NAMESPACE:-default}" -o wide
    fi
    ;;

delete)
    set -x
    (set -x; kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl delete -f -)
    kubectl delete ns "${NAMESPACE:-default}"
    ;;

show)
    set -x
    kubectl get -n "${NAMESPACE:-default}" all,configmap
    kubectl get -n "${NAMESPACE:-default}" pods,services -o wide
    kubectl get -n "${NAMESPACE:-default}" events | tail -10
    ;;

describe)
    set -x
    kubectl describe -n "${NAMESPACE:-default}" pod/${POD_NAME}
    ;;

logs)
    set -x
    kubectl logs -n "${NAMESPACE:-default}" pod/${POD_NAME}
    ;;

show-registry)
    test -z "${REGISTRY_FQDN_AND_PORT}" && { echo "ERROR: A required environment variable is missing. : NAME='REGISTRY_FQDN_AND_PORT'"; exit 1;}
    DOCKER_USER="alice"
    DOCKER_PASS=$(cat ${SCRIPT_DIR}/../.pass-alice)
    set -x
    curl -u ${DOCKER_USER}:${DOCKER_PASS} https://${REGISTRY_FQDN_AND_PORT}/v2/_catalog
    curl -X GET -u ${DOCKER_USER}:${DOCKER_PASS} https://${REGISTRY_FQDN_AND_PORT}/v2/greet-go/tags/list
    ;;

test-cluster-ip)
    set -x
    CLUSTER_IP_AND_PORT=$(kubectl get -n "${NAMESPACE:-default}" services "${SERVICE_NAME}" -o 'jsonpath={.spec.clusterIP}{":"}{.spec.ports[0].port}')
    kubectl run -q -n "${NAMESPACE:-default}" --rm -it curl \
--image=curlimages/curl \
--restart=Never -- \
-L http://${CLUSTER_IP_AND_PORT}/api/greet/John | python3 -m json.tool
    ;;

test-external)
    set -x
    EXTERNAL_IP_AND_PORT=$(kubectl get -n "${NAMESPACE:-default}" services "${SERVICE_NAME}" -o 'jsonpath={.status.loadBalancer.ingress[*].ip}{":"}{.spec.ports[0].port}')
    curl -v http://${EXTERNAL_IP_AND_PORT}/api/greet/John --header "Content-Type: application/json" | python3 -m json.tool
    ;;

esac
