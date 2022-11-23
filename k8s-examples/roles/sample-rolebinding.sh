#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})
usage() {
  cat 1>&2 <<EOF
Usage: $0 {apply|delete|show|can-i|test1|test2|test3_scale}
EOF
}

NAMESPACE="rbac-demo"
CMD=$1
case $1 in
apply)
    (set -x; kubectl apply -f ${SCRIPT_DIR}/sample-rolebinding.yaml)
    ;;

delete)
    (set -x; kubectl delete -f ${SCRIPT_DIR}/sample-rolebinding.yaml)
    ;;

show)
    # (set -x; kubectl get -f ${SCRIPT_DIR}/sample-rolebinding.yaml)
    set -x
    kubectl get role,rolebinding,serviceaccount,pods -n ${NAMESPACE}
    ;;

can-i)
    set -x
    kubectl exec -n rbac-demo -it sample-kubectl -- kubectl auth can-i -n ${NAMESPACE} create deployment
    kubectl exec -n rbac-demo -it sample-kubectl -- kubectl auth can-i -n ${NAMESPACE} patch replicasets/scale
    kubectl exec -n rbac-demo -it sample-kubectl -- kubectl auth can-i -n ${NAMESPACE} list pods
    ;;

test1)
    (set -x; kubectl exec -n rbac-demo -it sample-kubectl -- kubectl)
    ;;

test2)
    (set -x; kubectl exec -n rbac-demo -it sample-kubectl -- kubectl create deployment nginx --image=nginx:1.23.2-alpine)
    ;;

test3_scale)
    echo "*** NG ***"
    (set -x; kubectl exec -n rbac-demo -it sample-kubectl -- kubectl scale replicasets.apps -l app=nginx --replicas 2)
    echo "*** OK ***"
    (set -x; kubectl exec -n rbac-demo -it sample-kubectl -- kubectl scale deployment -l app=nginx --replicas 2)
    ;;

*)
    usage
    exit 1
    ;;
esac
