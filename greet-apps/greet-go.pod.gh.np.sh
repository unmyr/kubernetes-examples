#!/bin/bash
SCRIPT_PATH_IN=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname ${SCRIPT_PATH_IN})

usage() {
  cat 1>&2 <<EOF
Usage: $0 {apply|delete|show|curl|image-ls}
EOF
}

. ${SCRIPT_DIR}/../.env

CMD=$1
NAMESPACE="demo"
SA_NAME="greet-go-sa"

case $CMD in
    apply)
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
  imagePullSecrets:
  - name: ghcr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: greet-go-nodeport
  namespace: ${NAMESPACE}
spec:
  type: NodePort
  selector:
    app: greet-go-app
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
    nodePort: 30000
EOF
    ;;

show)
    (set -x; kubectl get -n ${NAMESPACE} secrets,serviceaccount,pods,services)
    (set -x; kubectl get -n ${NAMESPACE} serviceaccount ${SA_NAME} -o yaml)
    ;;

delete)
    (set -x; kubectl delete -n ${NAMESPACE} service greet-go-nodeport)
    (set -x; kubectl delete -n ${NAMESPACE} pod greet-go-pod)
    (set -x; kubectl delete -n ${NAMESPACE} serviceaccount ${SA_NAME})
    (set -x; kubectl delete -n ${NAMESPACE} secrets ghcr-secret)
    (set -x; kubectl delete ns ${NAMESPACE})
    ;;

curl)
    set -x
    curl -s http://127.0.0.1:30000/api/greet/John | python3 -m json.tool
    ;;

image-ls)
    (set -x; docker exec -it $(kind get clusters)-control-plane crictl images | grep -E 'IMAGE ID|greet-go')
    ;;

*)
    usage
    exit 1
esac
