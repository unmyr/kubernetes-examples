#!/bin/bash
usage() {
    cat 1>&2 <<EOF
usage: $0 {apply|delete|describe|logs|show}
EOF
}

NAMESPACE="hello-tekton-pipeline"
APP_NAME="hello-tekton-pipeline"
STEP_NAME="step-greetings"

SUB_COMMAND=$1

case ${SUB_COMMAND} in
apply)
    set -x
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl apply -f -
    kubectl apply -n "${NAMESPACE}" -f pipeline.yaml
    kubectl apply -n "${NAMESPACE}" -f pipeline-run.yaml
    ;;

delete)
    set -x
    kubectl delete pipeline.tekton.dev,pipelinerun.tekton.dev,task.tekton.dev,taskrun.tekton.dev,pod -n "${NAMESPACE}" -l app=${APP_NAME}

    # kubectl get all,task.tekton.dev,taskrun.tekton.dev,configmap,secrets,serviceaccount -n "${NAMESPACE}"
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events', 'addresspools.metallb.io']])])"
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl delete -f -
    ;;

show)
    (set -x; kubectl get all,pipeline.tekton.dev,pipelinerun.tekton.dev,task.tekton.dev,taskrun.tekton.dev,configmap,secrets,serviceaccount -n "${NAMESPACE}" -l app=${APP_NAME})
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
    for POD_NAME in $(kubectl get pods -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{.items[*].metadata.name}'); do
        for CONTAINER_NAME in $(kubectl get pods -n "${NAMESPACE}" "${POD_NAME}" --output=jsonpath='{.spec.containers[*].name}'); do
            (set -x; kubectl logs -n "${NAMESPACE}" "${POD_NAME}" -c "${CONTAINER_NAME}")
        done
    done
    ;;

*)
    usage
    ;;
esac
