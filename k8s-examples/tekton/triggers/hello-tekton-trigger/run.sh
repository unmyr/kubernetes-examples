#!/bin/bash
usage() {
    cat 1>&2 <<EOF
usage: $0 {apply|delete|describe|events|logs|show|trigger}
EOF
}

NAMESPACE="hello-tekton-trigger"
APP_NAME="hello-tekton-trigger"
STEP_NAME="step-greetings"

SUB_COMMAND=$1

case ${SUB_COMMAND} in
apply)
    set -x
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl apply -f -
    kubectl apply -f rbac.yaml
    kubectl -n "${NAMESPACE}" apply -f rbac.yaml -f pipeline.yaml -f trigger.yaml
    ;;

delete)
    set -x
    kubectl -n $NAMESPACE delete pipeline.tekton.dev,pipelinerun.tekton.dev,pod,task.tekton.dev,taskrun.tekton.dev,triggertemplate.triggers.tekton.dev,triggerbinding.triggers.tekton.dev,eventlistener.triggers.tekton.dev -l app=${APP_NAME}
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events', 'addresspools.metallb.io']])])"
    kubectl apply -f rbac.yaml
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events', 'addresspools.metallb.io']])])"
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl delete -f -
    ;;

trigger)
    set -x
    kubectl run -q -n $NAMESPACE -it curl --image=curlimages/curl --rm --restart=Never -- -v -H 'content-Type: application/json' http://el-hello-listener.${NAMESPACE}.svc.cluster.local:8080 -d '{"username": "Tekton"}'
    ;;

show)
    (set -x; kubectl get all,clusterrolebinding.rbac.authorization.k8s.io,deployment.apps,endpointslice.discovery.k8s.io,eventlistener.triggers.tekton.dev,pipeline.tekton.dev,pipelinerun.tekton.dev,rolebinding.rbac.authorization.k8s.io,task.tekton.dev,taskrun.tekton.dev,triggerbinding.triggers.tekton.dev,triggertemplate.triggers.tekton.dev -n "${NAMESPACE}" -l app=${APP_NAME})
    set -x
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events', 'addresspools.metallb.io']])])"
    # kubectl -n "${NAMESPACE}" get -f pipeline.yaml -f trigger.yaml -f rbac.yaml
    ;;

events)
    (set -x; kubectl get events -n "${NAMESPACE}")
    ;;

describe)
    kubectl get taskrun.tekton.dev -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read JOB_NAME; do
        (set -x; kubectl describe -n "${NAMESPACE}" "taskrun.tekton.dev/${JOB_NAME}")
    done

    kubectl get pod -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read POD_NAME; do
        (set -x; kubectl describe -n "${NAMESPACE}" "pod/${POD_NAME}")
    done
    ;;

logs)
    echo "# Log of tekton.dev/pipelineRun"
    (set -x; kubectl get pipelinerun.tekton.dev -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{.items[*].metadata.name}')
    for PIPELINE_RUN_NAME in $(kubectl get pipelinerun.tekton.dev -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{.items[*].metadata.name}');do
        (set -x; kubectl logs -n "${NAMESPACE}" --selector=tekton.dev/pipelineRun=${PIPELINE_RUN_NAME} -c "${STEP_NAME}")
    done
    echo

    echo "# Log of tekton.dev/taskRun"
    for TASK_RUN_NAME in $(kubectl get taskrun.tekton.dev -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{.items[*].metadata.name}'); do
        (set -x; kubectl logs -n "${NAMESPACE}" --selector=tekton.dev/taskRun=${TASK_RUN_NAME} -c "${STEP_NAME}")
    done
    echo

    echo "# Pod logs"
    for POD_NAME in $(kubectl get pods -n "${NAMESPACE}" --output=jsonpath='{.items[*].metadata.name}'); do
        for CONTAINER_NAME in $(kubectl get pods -n "${NAMESPACE}" "${POD_NAME}" --output=jsonpath='{.spec.containers[*].name}'); do
            (set -x; kubectl logs -n "${NAMESPACE}" "${POD_NAME}" -c "${CONTAINER_NAME}")
        done
    done
    ;;

*)
    usage
    ;;
esac
