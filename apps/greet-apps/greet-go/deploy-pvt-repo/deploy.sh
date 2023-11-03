#!/bin/bash
NAMESPACE="greet-go"
APP_NAME="greet-go-pvt-repo"
POD_NAME="greet-go-pod"
SERVICE_NAME="greet-go-service"

. ./.env

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
create)
    test -z "${PRIVATE_NS}" && { echo "ERROR: A required environment variable is missing. : NAME='PRIVATE_NS'"; exit 1;}
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
  - '.dockerconfigjson=.docker/docker-registry.json'

patches:
- patch: |-
    apiVersion: v1
    kind: Pod
    metadata:
      name: ${POD_NAME}
    spec:
      dnsPolicy: None
      dnsConfig:
        nameservers:
        - ${PRIVATE_NS}
EOF
    set -x
    kubectl create ns "${NAMESPACE:-default}" --dry-run=client -o yaml | kubectl apply -f -
    kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl apply -f -
    kubectl wait -n "${NAMESPACE:-default}" --for=condition=Ready --timeout=10s pod/${POD_NAME}
    kubectl describe pods -n "${NAMESPACE:-default}"
    kubectl get pods -n "${NAMESPACE:-default}" -o wide
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
    ;;

describe)
    set -x
    kubectl describe -n "${NAMESPACE:-default}" pod/${POD_NAME}
    ;;

logs)
    set -x
    kubectl get -n "${NAMESPACE:-default}" pod/${APP_NAME}
    ;;

registry)
    test -z "${REGISTRY_FQDN_AND_PORT}" && { echo "ERROR: A required environment variable is missing. : NAME='REGISTRY_FQDN_AND_PORT'"; exit 1;}
    set -x
    curl -u alice:$(cat .pass-alice) https://${REGISTRY_FQDN_AND_PORT}/v2/_catalog
    curl -X GET -u alice:$(cat .pass-alice) https://${REGISTRY_FQDN_AND_PORT}/v2/greet-go/tags/list
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
    curl http://${EXTERNAL_IP_AND_PORT}/api/greet/John --header "Content-Type: application/json" | python3 -m json.tool
    ;;

esac