#!/bin/bash
usage() {
    cat 1>&2 <<EOF
usage: $0 {apply|delete|describe|show|memory}
EOF
}

NAMESPACE="python-cron-job"
APP_NAME="python-cron-job"

SUB_COMMAND=$1

case ${SUB_COMMAND} in
generate)
    cat > workload.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${NAMESPACE}
  name: ${APP_NAME}-src
  labels:
    app: ${APP_NAME}
data:
  main.py: |
$(sed -s '1,$s/^/    /; s/^ *$//' main.py)
---
apiVersion: batch/v1
kind: CronJob
metadata:
  namespace: ${NAMESPACE}
  name: ${APP_NAME}
  labels:
    app: ${APP_NAME}
spec:
  schedule: "* * * * *"
  concurrencyPolicy: "Forbid"
  failedJobsHistoryLimit: 10
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            app: ${APP_NAME}
        spec:
          restartPolicy: Never
          containers:
          - name: default
            image: python:3.8-slim-buster
            imagePullPolicy: IfNotPresent
            command: ["python", "/app/main.py"]
            volumeMounts:
            - mountPath: "/app"
              name: app-volume
              readOnly: true
            resources:
              requests:
                cpu: "4m"
                memory: "64Mi"
              limits:
                cpu: "167m"
                memory: "128Mi"
          volumes:
          - name: app-volume
            configMap:
              name: ${APP_NAME}-src
EOF
    (set -x; GIT_PAGER= git diff workload.yaml)
    ;;

apply)
    set -x
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl apply -f -
    kubectl delete cronjob.batch -n "${NAMESPACE}" -l app=${APP_NAME}
    kubectl apply -n "${NAMESPACE}" -f workload.yaml
    ;;

delete)
    set -x
    kubectl delete configmap,cronjob.batch,job.batch,pod -n "${NAMESPACE}" -l app=${APP_NAME}
    kubectl get all,configmap,cronjob.batch,job.batch,pod -n "${NAMESPACE}"
    printf "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: ${NAMESPACE}" | kubectl delete -f -
    ;;

show)
    set -x
    kubectl get all,configmap,cronjob.batch,job.batch,pod -n "${NAMESPACE}"
    ;;

describe)
    kubectl get job.batch -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read JOB_NAME; do
        (set -x; kubectl describe -n "${NAMESPACE}" "job.batch/${JOB_NAME}")
    done

    kubectl get pod -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read POD_NAME; do
        (set -x; kubectl describe -n "${NAMESPACE}" "pod/${POD_NAME}")
    done
    ;;

logs)
    kubectl get job.batch -n "${NAMESPACE}" -l app=${APP_NAME} --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read JOB_NAME; do
        (set -x; kubectl logs -n "${NAMESPACE}" "job.batch/${JOB_NAME}")
    done
    ;;

memory)
    kubectl get pod -n "${NAMESPACE}" -l app=${APP_NAME} --field-selector=status.phase=Running --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read POD_NAME; do
        for CONTAINER_NAME in $(kubectl -n "${NAMESPACE}" get pod/${POD_NAME} --output=jsonpath='{.spec.containers[*].name}'); do
            set -x
            MEM_BYTES=$(kubectl exec -n "${NAMESPACE}" "pod/${POD_NAME}" -c "${CONTAINER_NAME}" -- cat /sys/fs/cgroup/memory/memory.usage_in_bytes)
            set +x
            python3 -c "print(f\"{${MEM_BYTES}/(1024*1024):.1f} MB\")"
        done
    done
    (set -x; kubectl top pod -n $NAMESPACE)
    (set -x; kubectl describe PodMetrics -n $NAMESPACE)
    ;;

*)
    usage
    ;;
esac
