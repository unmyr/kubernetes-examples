#!/bin/bash
NAMESPACE="my-private-registry-demo"
APP_NAME="my-registry"
MY_SERVICE_NAME="my-registry-service"
REGISTRY_FQDN_AND_PORT="${MY_SERVICE_NAME}.${NAMESPACE}.svc:5000"

. ./.env

test -z "${REGISTRY_FQDN_AND_PORT}" && { echo "ERROR: A required environment variable is missing. : NAME='REGISTRY_FQDN_AND_PORT'"; exit 1;}

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
create)
    mkdir -p basic-auth/
    rm -f ./basic-auth/registry.password
    if [ ! -f basic-auth/registry.password ]; then
        pwgen 12 1 | tr -d '\n' > .pass-alice
        cat .pass-alice | htpasswd -B -i -c basic-auth/registry.password alice
    fi
    REGISTRY_AUTH_HTPASSWD_PATH=/var/lib/registry/auth/registry.password
    cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
commonLabels:
  app: ${APP_NAME}
namespace: ${NAMESPACE}

resources:
- deployment.yaml
- service.yaml

configMapGenerator:
- name: my-private-registry
  files:
  - ./basic-auth/registry.password
  literals:
  - MY_SERVICE_NAME=${MY_SERVICE_NAME}
  - REGISTRY_AUTH_HTPASSWD_PATH=${REGISTRY_AUTH_HTPASSWD_PATH}

patches:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: ${APP_NAME}
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/volumeMounts/0/mountPath
        value: /var/lib/registry/auth
EOF
    set -x
    kubectl create ns "${NAMESPACE:-default}" --dry-run=client -o yaml | kubectl apply -f -

    kubectl kustomize ./ | tee .kustomization-out.yaml | kubectl apply -f -

    kubectl wait -n "${NAMESPACE:-default}" --for=condition=Available deployments --selector=app=${APP_NAME} --timeout=90s
    kubectl get pods -n "${NAMESPACE:-default}"
    kubectl describe pods -n "${NAMESPACE:-default}"
    POD_NAME=$(kubectl get -n "${NAMESPACE:-default}" pods -l app=${APP_NAME} -o jsonpath="{.items[0].metadata.name}")
    kubectl run -q -n "${NAMESPACE:-default}" -it --rm curl-${RANDOM} --image=curlimages/curl --restart=Never -- -u "alice:$(cat ./.pass-alice)" http://${REGISTRY_FQDN_AND_PORT}/v2/_catalog
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
