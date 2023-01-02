#!/bin/bash
usage() {
    cat 1>&2 <<EOF
usage: $0 {apply|delete|show|exec}
EOF
}

CMD=$1
SECRET_NAME="postgres-client-sb"

case ${CMD} in
apply)
    . .env
    set -x
    kubectl apply -f service-binding.yaml
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
type: servicebinding.io/postgresql
stringData:
  type: postgresql
  host: postgres-service.postgres.svc.cluster.local
  port: "5432"
  database: fruits
  username: db_user1
  password: ${PGPASSWORD}
EOF
    kubectl apply -f workload.yaml
    ;;

delete)
    set -x
    kubectl delete -f workload.yaml
    kubectl delete secret ${SECRET_NAME}
    kubectl delete -f service-binding.yaml
    ;;

show)
    set -x
    kubectl get servicebinding postgres-client-sb
    kubectl get secrets --field-selector="type=servicebinding.io/postgresql"
    kubectl get all -l app=postgres-client-sb
    kubectl describe servicebinding/postgres-client-sb
    ;;

exec)
    kubectl exec -it deployment.apps/postgres-client-sb -- bash -c "echo 'SELECT * FROM fruits_menu;' | psql"
    ;;

*)
    usage
    ;;
esac
