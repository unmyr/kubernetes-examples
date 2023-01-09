#!/bin/bash
NAMESPACE="secret-ex2"
SECRET_NAME="secret-ex2"

usage() {
    cat 1>&2 <<EOF
usage: $0 {create|delete|list|show|show-one|show-all}
EOF
}

CMD=$1
case $CMD in
create)
    set -x
    kubectl create -f .
    ;;

delete)
    set -x
    time kubectl delete -f .
    ;;

list)
    set -x
    kubectl get namespace ${NAMESPACE}
    kubectl get all,serviceaccount,secrets -n ${NAMESPACE}
    ;;

show)
    set -x
    kubectl get namespace ${NAMESPACE} -o yaml
    kubectl get serviceaccount -n ${NAMESPACE} default -o yaml
    kubectl get secrets -n ${NAMESPACE} ${SECRET_NAME} -o yaml
    ;;

show-one)
    set -x
    : Using base64 command
    printf "user.name: %s\n" \
"$(kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.user\.name}' | base64 -d)"
    printf "user.name: %s\n" \
$(kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['user\.name']}" | base64 -d)
    printf "connect-string: %s\n" \
"$(kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.connect-string}' | base64 -d)"
    printf "comment: %s\n" \
"$(kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.comment}' | base64 -d)"

    : Using go-template
    kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o go-template --template '{{"user.name: "}}{{ index .data "user.name" | base64decode }}{{ "\n" }}'
    kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o go-template --template '{{"connect-string: "}}{{ index .data "connect-string" | base64decode }}{{ "\n" }}'
    kubectl get secrets/${SECRET_NAME} -n ${NAMESPACE} -o go-template --template '{{"comment: "}}{{ .data.comment | base64decode }}{{ "\n" }}'
    ;;

show-all)
    set -x
    kubectl get secrets -n ${NAMESPACE} ${SECRET_NAME} -o json | jq '.data |= map_values(@base64d)'
    kubectl get secret -n ${NAMESPACE} ${SECRET_NAME} -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
    ;;

*)
    usage
    ;;

esac
