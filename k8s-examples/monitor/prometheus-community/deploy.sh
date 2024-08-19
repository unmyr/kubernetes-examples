#!/bin/bash
usage() {
    MESSAGE="$1"
    test -n "${MESSAGE}" && echo "${MESSAGE}" 1>&2
    cat <<EOF
usage:
  $0 {apply|delete}
  $0 {show|show_secrets}
  $0 {test}
EOF
}

# MY_RELEASE_NAME="prometheus-grafana"
# MY_RELEASE_NAME="prometheus"
MY_RELEASE_NAME="prom-g"
NAMESPACE_PROMETHEUS=${NAMESPACE_PROMETHEUS:-prometheus-grafana}
NAMESPACE_GRAFANA=${NAMESPACE_GRAFANA:-prometheus-grafana}

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
apply)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
    test -f Chart.yaml || {
        GIT_USER="prometheus-community"
        TAG="kube-prometheus-stack-61.9.0"
        curl -sOL https://raw.githubusercontent.com/${GIT_USER}/helm-charts/${TAG}/charts/kube-prometheus-stack/Chart.yaml
    }

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm list -n "${NAMESPACE_PROMETHEUS}"
    # helm diff upgrade --install "${MY_RELEASE_NAME}" prometheus-community/kube-prometheus-stack --namespace "${NAMESPACE_PROMETHEUS}" -f ./values.yaml
    kubectl get -n "${NAMESPACE_PROMETHEUS}" all
    set +x

    read -p "Do you want to continue?(y/N): " yn
    case "$yn" in
    [yY]*) true;;
    *) exit 1;;
    esac
    set -x
    helm upgrade --install "${MY_RELEASE_NAME}" prometheus-community/kube-prometheus-stack --namespace "${NAMESPACE_PROMETHEUS}" --create-namespace -f ./values.yaml
    kubectl rollout status -n "${NAMESPACE_PROMETHEUS}" deployments.apps -l app.kubernetes.io/instance=${MY_RELEASE_NAME}
    ;;

delete)
    echo "Timestamp: $(date --iso-8601=second)"
    NAMESPACE_PROMETHEUS=$(kubectl get -A deploy -l app.kubernetes.io/instance=${MY_RELEASE_NAME} -o jsonpath='{.items[0].metadata.namespace}{"\n"}')
    test -n "${NAMESPACE_PROMETHEUS}" && (
        set -x
        helm uninstall --namespace "${NAMESPACE_PROMETHEUS}" "${MY_RELEASE_NAME}"
        kubectl wait --for=delete pods -l app.kubernetes.io/instance=${MY_RELEASE_NAME} --timeout=60s
        kubectl delete -A all,secrets,cm -l app.kubernetes.io/instance=${MY_RELEASE_NAME}
        kubectl delete ns "${NAMESPACE_PROMETHEUS}"
    )
    set -x
    kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
    kubectl delete crd alertmanagers.monitoring.coreos.com
    kubectl delete crd podmonitors.monitoring.coreos.com
    kubectl delete crd probes.monitoring.coreos.com
    kubectl delete crd prometheusagents.monitoring.coreos.com
    kubectl delete crd prometheuses.monitoring.coreos.com
    kubectl delete crd prometheusrules.monitoring.coreos.com
    kubectl delete crd scrapeconfigs.monitoring.coreos.com
    kubectl delete crd servicemonitors.monitoring.coreos.com
    kubectl delete crd thanosrulers.monitoring.coreos.com
    ;;

test)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    GRAFANA_SVC_NAME="${MY_RELEASE_NAME}-grafana"
    GRAFANA_TOKEN=$(kubectl get --namespace "${NAMESPACE_GRAFANA}" secret/${GRAFANA_SVC_NAME} -o go-template='{{index .data "admin-user" | base64decode}}{{":"}}{{index .data "admin-password" | base64decode}}{{"\n"}}')
    kubectl run -q -n "${NAMESPACE:-default}" -it curl --image=curlimages/curl --rm --restart=Never -- -s -L http://${GRAFANA_SVC_NAME}.${NAMESPACE_PROMETHEUS}.svc.cluster.local:80/api/health -H "Accept: application/json" --user ${GRAFANA_TOKEN}
    ;;

show)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    helm list -A -l name=${MY_RELEASE_NAME}
    kubectl get -n "${NAMESPACE_PROMETHEUS}" deploy,svc -l app.kubernetes.io/instance=${MY_RELEASE_NAME}

    ;;

show_secrets)
    echo "Timestamp: $(date --iso-8601=second)"
    set -x
    kubectl get --namespace "${NAMESPACE_GRAFANA}" secret/${MY_RELEASE_NAME}-grafana -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
    ;;

*)
    usage "ERROR: Unsupported subcommand : SUB-COMMAND='${SUB_COMMAND}'"
    exit 1
    ;;
esac
