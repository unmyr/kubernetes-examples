DB_USER_NAME=dbuser1
DB_NAME="fruits"
SCHEMA_NAME=dbuser1

.PHONY: clean create log service show sql

create:
	@echo -n "+ "
	./secret.sh create
	@echo -n "+ "
	kubectl apply -f postgres.pod.yaml

clean:
	@echo -n "+ "
	kubectl delete -f postgres.pod.yaml
	@echo -n "+ "
	./secret.sh delete

show:
	@echo -n "+ "
	kubectl get configmap pg-initdb-config
	@echo -n "+ "
	-kubectl get pods postgres-pod
	@echo -n "+ "
	-kubectl describe pod postgres-pod
	@echo -n "+ "
	-kubectl logs postgres-pod

service:
	@echo -n "+ "
	kubectl get services postgres-service

log:
	@echo -n "+ "
	kubectl logs postgres-pod

update_pass:
	@echo -n "+ "
	printf "ALTER ROLE dbuser1 WITH LOGIN PASSWORD '%s';" $(shell grep ADDITIONAL_PASSWORD .env | sed -e 's/^.*=//') | psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -d fruits -U postgres

sql:
	@echo -n "+ "
	psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -c "SHOW search_path;"
	@echo -n "+ "
	psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM fruits_menu;"
	@echo -n "+ "
	psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM $(SCHEMA_NAME).fruits_menu;"
	@echo -n "+ "
	psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -c "INSERT INTO $(SCHEMA_NAME).fruits_menu (name, price) VALUES ('Peach', 200);"
	@echo -n "+ "
	psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -c "UPDATE $(SCHEMA_NAME).fruits_menu SET price = 112 WHERE name = 'Orange';"
	@echo -n "+ "
	psql -h $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -c "DELETE FROM $(SCHEMA_NAME).fruits_menu WHERE name = 'Peach';"
