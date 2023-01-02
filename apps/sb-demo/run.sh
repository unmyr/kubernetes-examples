#!/bin/bash
usage() {
    cat 1>&2 <<EOF
usage: $0 {apply|delete|show|curl|logs|inspect}

usage: $0 {load-to-kind|remove-from-kind}
EOF
}

CMD=$1
SECRET_NAME="service-bindings-demo-secrets"
SERVICE_NAME="service-bindings-demo-service"

case ${CMD} in
load-to-kind)
    set -x
    kind --name kind-1 load docker-image service-bindings-demo:0.0.1
    ;;

remove-from-kind)
    set -x
    docker exec kind-1-control-plane crictl images | grep -E 'docker.io/library/service-bindings-demo' | awk '{print $3}' | xargs --no-run-if-empty docker exec kind-1-control-plane crictl rmi
    ;;

apply)
    set -x
    kubectl apply -f service-binding.yaml -f workload.yaml
    ;;

delete)
    set -x
    kubectl delete -f service-binding.yaml -f workload.yaml
    ;;

show)
    set -x
    kubectl get servicebinding service-bindings-demo-sb
    kubectl get secrets --field-selector="type=servicebinding.io/custom"
    kubectl get all -l app=service-bindings-demo
    kubectl describe servicebinding/service-bindings-demo-sb
    ;;

curl)
    set -x
    EXTERNAL_IP=$(kubectl get services ${SERVICE_NAME} -o jsonpath='{.status.loadBalancer.ingress[*].ip}')
    EXTERNAL_PORT=$(kubectl get services ${SERVICE_NAME} -o jsonpath='{.spec.ports[0].port}')
    curl -s http://${EXTERNAL_IP}:${EXTERNAL_PORT}/ --header "Content-Type: application/json" | python3 -m json.tool
    ;;

logs)
    kubectl get pods -l app=service-bindings-demo --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read POD_NAME; do
        (set -x; kubectl logs ${POD_NAME});
    done
    ;;

inspect)
    set -x
    kubectl exec -it deployment.apps/service-bindings-demo-dep -- bash -c "env | grep SERVICE_BINDING_ROOT"
    kubectl exec -it deployment.apps/service-bindings-demo-dep -- bash -c "find \${SERVICE_BINDING_ROOT}"
    ;;

*)
    usage
    ;;
esac
