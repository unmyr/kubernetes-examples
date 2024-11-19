#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_NAME=$(basename ${SCRIPT_PATH_IN} .sh)
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})
WORK_DIR=$(mktemp -d -p /tmp ${SCRIPT_NAME}.XXXX)
trap 'rm -rf -- "${WORK_DIR}"' EXIT

usage() {
    cat 1>&2 <<EOF
usage:
$0 {preview_pv}
$0 {create|delete_dbs|delete_pv}
$0 {show|show_all|show_pv|describe|logs}
EOF
}

get_k_postgres() {
    APP_NAME="$1"
    NAMESPACE="$2"
    KUBE_NODENAME="$3"

    #
    cat <<EOF > postgres/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}
commonLabels:
  app.kubernetes.io/part-of: ${APP_NAME}
resources:
- pvc.yaml
- deployment.yaml
- service.yaml

patches:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: postgres-1
  patch: |-
    - op: replace
      path: /spec/template/spec/nodeName
      value: ${KUBE_NODENAME}

generatorOptions:
  labels:
    app: postgres

configMapGenerator:
- name: pg-initdb-config
  files:
    - 1_init_user_db.sh
    - 2_create_tables.sh

secretGenerator:
- name: postgres-secret
  envs:
  # .env.postgres
  # POSTGRES_USER=postgres
  # POSTGRES_PASSWORD=************
  # DEFAULT_DB_NAME=fruits
  # ADDITIONAL_USER=db_user1
  # ADDITIONAL_PASSWORD=************
  - .env.postgres
EOF
}

gen_k_pv() {
    APP_NAME="$1"
    NAMESPACE="$2"
    KUBE_NODENAME="$3"
    MOUNT_POINT="$4"

    cat <<EOF > volumes/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}
commonLabels:
  app.kubernetes.io/part-of: ${APP_NAME}
resources:
- pv.yaml

patches:
  - target:
      version: v1
      kind: PersistentVolume
      name: postgres-data-pv
    patch: |-
      - op: replace
        path: /spec/local/path
        value: ${MOUNT_POINT}
  - target:
      version: v1
      kind: PersistentVolume
      name: postgres-data-pv
    patch: |-
      - op: replace
        path: "/spec/nodeAffinity/required/nodeSelectorTerms/0/matchExpressions/0/values/0"
        value: ${KUBE_NODENAME}
EOF
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi
SUB_COMMAND=$1

# Load environment-dependent variables (Required)
test -f .env && . .env

# Set hard-coded variables in yaml
APP_NAME="postgres"
NAMESPACE=${NAMESPACE:-${APP_NAME}}
PV_NAME="postgres-data-pv"

case "${SUB_COMMAND}" in
preview_pv)
    test -z "${KUBE_NODENAME}" && { echo "ERROR: A required environment variable is missing. : NAME='KUBE_NODENAME'"; exit 1;}
    test -z "${MOUNT_POINT}" && { echo "ERROR: A required environment variable is missing. : NAME='MOUNT_POINT'"; exit 1;}

    echo "Timestamp: $(date --iso-8601=second)"
    gen_k_pv "${APP_NAME:-postgres}" "${NAMESPACE:-postgres}" "${KUBE_NODENAME}" "${MOUNT_POINT}"

    set -x
    (set -x; kubectl create -k ./volumes --dry-run=client -o yaml > volumes/.kustomization-out.yaml)
    echo "Generate: volumes/.kustomization-out.yaml"
    (kubectl diff -f volumes/.kustomization-out.yaml)
    ;;

preview_pg)
    test -z "${KUBE_NODENAME}" && { echo "ERROR: A required environment variable is missing. : NAME='KUBE_NODENAME'"; exit 1;}

    echo "Timestamp: $(date --iso-8601=second)"
    get_k_postgres "${APP_NAME:-postgres}" "${NAMESPACE:-postgres}" "${KUBE_NODENAME}"

    set -x
    (set -x; kubectl create -k ./postgres --dry-run=client -o yaml > postgres/.kustomization-out.yaml)
    echo "Generate: postgres/.kustomization-out.yaml"
    (kubectl diff -f postgres/.kustomization-out.yaml)
    ;;

create)
    test -z "${KUBE_NODENAME}" && { echo "ERROR: A required environment variable is missing. : NAME='KUBE_NODENAME'"; exit 1;}
    test -z "${MOUNT_POINT}" && { echo "ERROR: A required environment variable is missing. : NAME='MOUNT_POINT'"; exit 1;}

    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl create ns "${NAMESPACE:-postgres}" --dry-run=client -o yaml | kubectl apply -f -

    gen_k_pv "${APP_NAME:-postgres}" "${NAMESPACE:-postgres}" "${KUBE_NODENAME}" "${MOUNT_POINT}"
    kubectl kustomize volumes/ | kubectl apply -f -

    kubectl get -n "${NAMESPACE:-postgres}" -l app=${APP_NAME:-postgres} pv
    get_k_postgres "${APP_NAME:-postgres}" "${NAMESPACE:-postgres}" "${KUBE_NODENAME}"
    kubectl kustomize postgres/ | kubectl apply -f -
    time kubectl rollout status -n "${NAMESPACE:-postgres}" deploy -l app=${APP_NAME:-postgres}
    ;;

delete_dbs)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl delete -n "${NAMESPACE:-postgres}" -l app=${APP_NAME:-postgres} pvc,deploy,configmap,secrets,service,endpoints
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE:-postgres}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events', 'addresspools.metallb.io']])])"
    kubectl delete ns "${NAMESPACE:-postgres}"

    kubectl get pv -l app=${APP_NAME:-postgres} -o custom-columns=Namespace:.spec.claimRef.namespace,Name:.spec.claimRef.name
    kubectl patch "pv/${PV_NAME:-postgres-data-pv}" --patch='{"spec":{"claimRef": null}}'
    kubectl get pv -l app=${APP_NAME:-postgres} -o custom-columns=Namespace:.spec.claimRef.namespace,Name:.spec.claimRef.name
    ;;

delete_pv)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl delete pv -l app=${APP_NAME:-postgres}
    ;;

show)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl get storageclasses.storage.k8s.io --field-selector metadata.name=hostpath-class
    kubectl get -l app=${APP_NAME:-postgres} pv
    kubectl get -n "${NAMESPACE:-postgres}" -l app=${APP_NAME:-postgres} deploy,pods,configmap,secrets,service
    kubectl get -A events --sort-by='.lastTimestamp'
    kubectl get -n "${NAMESPACE:-postgres}" pods -l app=${APP_NAME:-postgres} -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
    ;;

show_pv)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl get -n "${NAMESPACE:-postgres}" -l app=${APP_NAME:-postgres} pv,pvc
    kubectl describe -n "${NAMESPACE:-postgres}" pv,pvc,deploy -l app=${APP_NAME:-postgres}
    kubectl get pv -l app=${APP_NAME:-postgres} -o custom-columns=Namespace:.spec.claimRef.namespace,Name:.spec.claimRef.name
    kubectl get events --field-selector involvedObject.kind=PersistentVolume
    ;;

show_all)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl api-resources --verbs=list --namespaced -o name | python3 -c "import subprocess, sys; subprocess.run(['kubectl', 'get', '-n', '${NAMESPACE:-postgres}', ','.join([x for x in sys.stdin.read().split() if x not in ['events.events.k8s.io', 'events', 'addresspools.metallb.io']])])"
    ;;

describe)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl -n "${NAMESPACE:-postgres}" describe pv,pvc,deploy -l app=${APP_NAME:-postgres}
    ;;

logs)
    echo "Timestamp: $(date --iso-8601=second)"
    while read LINE; do
        NS_AND_POD=($LINE)
        DB_NAMESPACE=${NS_AND_POD[0]}
        DB_POD_NAME=${NS_AND_POD[1]}
        (set -x; kubectl -n "${DB_NAMESPACE}" logs ${DB_POD_NAME})
    done< <(
      kubectl get -n "${NAMESPACE:-postgres}" pods -l app=${APP_NAME:-postgres} -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}'
    )
    ;;

*)
    usage
    exit 1
    ;;
esac
