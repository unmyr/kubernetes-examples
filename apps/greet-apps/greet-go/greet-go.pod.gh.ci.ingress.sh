#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

usage() {
  cat 1>&2 <<EOF
Usage: $0 {apply|delete|show|show-contour|curl-clusterIp|curl-contour}
EOF
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi
CMD=$1
NAMESPACE="demo"
SA_NAME="greet-go-sa"

case $CMD in
apply)
    . ${SCRIPT_DIR}/../.env
    set -x
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
---
apiVersion: v1
kind: Secret
metadata:
  name: ghcr-secret
  namespace: ${NAMESPACE}
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: |
    {
      "auths": {
        "https://ghcr.io": {
          "username": "${GITHUB_USERNAME}",
          "password": "${GITHUB_API_TOKEN}"
        }
      }
    }
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
imagePullSecrets:
- name: ghcr-secret
---
apiVersion: v1
kind: Pod
metadata:
  name: greet-go-pod
  labels:
    app: greet-go-app
  namespace: ${NAMESPACE}
spec:
  serviceAccountName: ${SA_NAME}
  containers:
  - name: greet-go
    image: ghcr.io/unmyr/greet-go:0.1
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  namespace: ${NAMESPACE}
  name: greet-go-service
spec:
  type: ClusterIP
  selector:
    app: greet-go-app
  ports:
    - name: http
      port: 3000
      targetPort: 8080
      protocol: TCP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: ${NAMESPACE}
  name: greet-go-ingress
  labels:
    app: greet-go-app
spec:
  defaultBackend:
    service:
      name: greet-go-service
      port:
        number: 3000
EOF
    ;;

delete)
    (set -x; kubectl delete ingress -n ${NAMESPACE} -l app=greet-go-app)
    (set -x; kubectl delete service -n ${NAMESPACE} greet-go-service)
    (set -x; kubectl delete pod -n ${NAMESPACE} -l app=greet-go-app)
    (set -x; kubectl delete ServiceAccount -n ${NAMESPACE} ${SA_NAME})
    (set -x; kubectl delete ns ${NAMESPACE})
    ;;

show)
    (set -x; kubectl get all,secrets,ServiceAccount,ingress -n ${NAMESPACE})
    ;;

show-contour)
    (set -x; kubectl -n projectcontour get deployment,daemonset,service)
    ;;

curl-clusterIp)
    set -x
    kubectl run -q -n ${NAMESPACE} -it curl --image=curlimages/curl --rm --restart=Never --wait=true -- -s -L http://greet-go-service.${NAMESPACE}.svc.cluster.local:3000/api/greet/John | python3 -m json.tool
    ;;

curl-contour)
    set -x
    kubectl -n projectcontour port-forward service/envoy 8888:80 &
    RUNNING_PID=$!
    sleep 0.1
    curl -s http://local.projectcontour.io:8888/api/greet/John | python3 -m json.tool
    kill -TERM ${RUNNING_PID}
    ;;

*)
    usage
    exit 1
    ;;
esac
