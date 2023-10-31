#!/bin/bash
NAMESPACE="my-private-registry-demo"
POD_NAME="test-docker-private-registry"
PRIVATE_NS=""
. ./.env.test
test -z "${PRIVATE_NS}" && { echo "ERROR: A required environment variable is missing. : NAME='PRIVATE_NS'"; exit 1;}
test -z "${REGISTRY_FQDN_AND_PORT}" && { echo "ERROR: A required environment variable is missing. : NAME='REGISTRY_FQDN_AND_PORT'"; exit 1;}

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
create)
    cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonLabels:
  app: test-dns-and-pvt-reg
namespace: ${NAMESPACE}

resources:
- pod.yaml
configMapGenerator:
- name: private-registry
  literals:
  - REGISTRY_FQDN_AND_PORT=${REGISTRY_FQDN_AND_PORT}
- name: ca-pem-store
  files:
  - ./certs/docker-registry.crt

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
    kubectl create ns "${NAMESPACE:-default}"
    set -x; kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl apply -f -
    kubectl wait -n "${NAMESPACE:-default}" --for=condition=Ready --timeout=60s pod/test-docker-private-registry
    kubectl get pods -n "${NAMESPACE:-default}"
    kubectl describe pods -n "${NAMESPACE:-default}"
    kubectl exec -n "${NAMESPACE:-default}" -it pod/test-docker-private-registry -- curl https://${REGISTRY_FQDN_AND_PORT}/v2/_catalog
    ;;

delete)
    set -x
    (set -x; kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl delete -f -)
    kubectl delete ns "${NAMESPACE:-default}"
    ;;

show)
    set -x
    kubectl get -n "${NAMESPACE:-default}" all,configmap
    ;;

esac