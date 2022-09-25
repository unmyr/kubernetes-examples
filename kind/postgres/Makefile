DB_USER_NAME=dbuser1
DB_NAME="fruits"
SCHEMA_NAME=dbuser1

.PHONY: clean create log service show sql

create:
	@echo -n "+ "
	./secret.sh create
	@echo -n "+ "
	kubectl apply -f postgres.pod.yaml
	@echo -n "+ "
	-kubectl get pods postgres-pod
	@echo -n "+ "
	kubectl wait --for condition=Ready --timeout=90s pod postgres-pod
	@echo -n "+ "
	-kubectl get pods postgres-pod
	@echo -n "+ "
	kubectl get services postgres-service
	@echo -n "+ "
    # lazy evaluation of string using shell
	psql -h $$(kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -f test.sql

create2:
	@echo -n "+ "
	./secret.sh create
	@echo -n "+ "
	kubectl apply -f postgres.pod.yaml
	@echo -n "+ "
	-kubectl get pods postgres-pod
	@echo -n "+ "
	timeout 30 bash -c "while [ -z $$(kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') ]; do sleep 1; done"
	@echo -n "+ "
	-kubectl get pods postgres-pod
	@echo -n "+ "
	kubectl get services postgres-service
	@echo -n "+ "
    # lazy evaluation of string using shell
	psql -h $$(kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -f test.sql

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

sql:
	$(eval TARGET_HOST := $(shell kubectl get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}'))
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "SHOW search_path;"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM fruits_menu;"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM $(SCHEMA_NAME).fruits_menu;"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "INSERT INTO $(SCHEMA_NAME).fruits_menu (name, price) VALUES ('Peach', 200);"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "UPDATE $(SCHEMA_NAME).fruits_menu SET price = 112 WHERE name = 'Orange';"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "DELETE FROM $(SCHEMA_NAME).fruits_menu WHERE name = 'Peach';"
