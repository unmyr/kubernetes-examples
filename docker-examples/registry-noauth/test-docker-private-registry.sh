#!/bin/bash
NAMESPACE="my-private-registry-demo"
PRIVATE_NS=""
. ./.env.test
test -z "${PRIVATE_NS}" && { echo "ERROR: A required environment variable is missing. : NAME='PRIVATE_NS'"; exit 1;}
test -z "${REGISTRY_FQDN_AND_PORT}" && { echo "ERROR: A required environment variable is missing. : NAME='REGISTRY_FQDN_AND_PORT'"; exit 1;}

cat > test-docker-private-registry.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: test-docker-private-registry
spec:
spec:
  containers:
  - name: default
    image: ubuntu:22.04
    env:
    - name: REGISTRY_FQDN_AND_PORT
      valueFrom:
        configMapKeyRef:
          name: private-registry
          key: REGISTRY_FQDN_AND_PORT
    volumeMounts:
    - name: ca-pem-store
      mountPath: /etc/ssl/certs/docker-registry.crt
      subPath: docker-registry.crt
      readOnly: false
    args:
    - /bin/sh
    - -c
    - update-ca-certificates; (apt-get update; apt-get install -y curl) & tail -f /dev/null
    startupProbe:
      exec:
        command:
        - which
        - curl
      initialDelaySeconds: 18
      periodSeconds: 3
      failureThreshold: 20
  dnsConfig:
    nameservers:
    - ${PRIVATE_NS}
  dnsPolicy: "None"
  restartPolicy: Never
  volumes:
  - name: ca-pem-store
    configMap:
      name: ca-pem-store
  - name: private-registry
    configMap:
      name: private-registry
EOF

SUB_COMMAND="$1"
case "${SUB_COMMAND}" in
create)
    set -x
    kubectl create ns "${NAMESPACE:-default}"
    kubectl create -n "${NAMESPACE:-default}" configmap ca-pem-store --from-file=certs/docker-registry.crt
    kubectl create -n "${NAMESPACE:-default}" configmap private-registry --from-env-file=./.env.test
    kubectl create -n "${NAMESPACE:-default}" -f test-docker-private-registry.yaml
    kubectl wait -n "${NAMESPACE:-default}" --for=condition=Ready --timeout=60s pod/test-docker-private-registry
    kubectl get pods -n "${NAMESPACE:-default}"
    kubectl describe pods -n "${NAMESPACE:-default}"
    kubectl exec -n "${NAMESPACE:-default}" -it pod/test-docker-private-registry -- curl https://${REGISTRY_FQDN_AND_PORT}/v2/_catalog
    ;;

delete)
    set -x
    kubectl delete -n "${NAMESPACE:-default}" -f test-docker-private-registry.yaml
    kubectl delete -n "${NAMESPACE:-default}" configmap ca-pem-store private-registry
    kubectl delete ns "${NAMESPACE:-default}"
    ;;

show)
    set -x
    kubectl get -n "${NAMESPACE:-default}" all,configmap
    ;;

esac