NAMESPACE=postgres
DB_USER_NAME=db_user1
DB_NAME="fruits"
SCHEMA_NAME=db_user1

.PHONY: clean create log service show sql

create:
	@echo -n "+ "
	./postgres.sh create
	@echo -n "+ "
	-kubectl -n $(NAMESPACE) get -l app=postgres pods,services
	@echo -n "+ "
	kubectl -n $(NAMESPACE) wait --for condition=Ready --timeout=90s pod postgres-pod
	@echo -n "+ "
	-kubectl -n $(NAMESPACE) get -l app=postgres pods,services
	@echo -n "+ "
	# lazy evaluation of string using shell
	psql -h $$(kubectl get -n $(NAMESPACE) services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -f test.sql

create2:
	@echo -n "+ "
	./postgres.sh create
	@echo -n "+ "
	-kubectl -n $(NAMESPACE) get -l app=postgres pods,services
	@echo -n "+ "
	timeout 30 bash -c "while [ -z $$(kubectl get -n $(NAMESPACE) services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') ]; do sleep 1; done"
	@echo -n "+ "
	-kubectl -n $(NAMESPACE) get -l app=postgres pods,services
	@echo -n "+ "
	# lazy evaluation of string using shell
	psql -h $$(kubectl -n $(NAMESPACE) get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}') -U $(DB_USER_NAME) -d fruits -f test.sql

clean:
	@echo -n "+ "
	-./postgres.sh delete

show:
	./postgres.sh show

service:
	@echo -n "+ "
	kubectl -n $(NAMESPACE) get services postgres-service

log:
	@echo -n "+ "
	kubectl -n $(NAMESPACE) logs postgres-pod

sql:
	$(eval TARGET_HOST := $(shell kubectl -n $(NAMESPACE) get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}'))
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

sql-ro:
	$(eval TARGET_HOST := $(shell kubectl -n $(NAMESPACE) get services postgres-service -o jsonpath='{.status.loadBalancer.ingress[*].ip}'))
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "SHOW search_path;"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM fruits_menu;"
	@echo -n "+ "
	psql -h $(TARGET_HOST) -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM $(SCHEMA_NAME).fruits_menu;"
