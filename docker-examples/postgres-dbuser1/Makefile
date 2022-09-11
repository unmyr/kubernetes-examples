COTAINER_NAME=postgres-dbuser1
DATA_DIR=/var/tmp/$(COTAINER_NAME)/
DB_USER_NAME=dbuser1
DB_NAME="fruits"

.PHONY: start stop

start:
	@echo -n "+ "
	docker-compose up -d
	@echo -n "+ "
	docker ps -a --filter "name=postgres" --format "{{.State}} {{.Status}}"
	@echo -n "+ "
	../bin/psql_wait_ready $(DB_USER_NAME)
	@echo -n "+ "
	docker ps -a --filter "name=postgres" --format "{{.State}} {{.Status}}"
	@echo -n "+ "
	../bin/psql_wait_table_created $(DB_USER_NAME) $(DB_NAME) fruits_menu
	@echo -n "+ "
	docker ps -a --filter "name=postgres" --format "{{.State}} {{.Status}}"
	@echo -n "+ "
	docker logs $(COTAINER_NAME)
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "SHOW search_path;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM $(DB_USER_NAME).fruits_menu;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "INSERT INTO $(DB_USER_NAME).fruits_menu (name, price) VALUES ('Peach', 200);"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "UPDATE $(DB_USER_NAME).fruits_menu SET price = 112 WHERE name = 'Orange';"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "DELETE FROM $(DB_USER_NAME).fruits_menu WHERE name = 'Peach';"

status:
	@echo -n "+ "
	docker ps -a --filter "name=postgres" --format "{{.State}} {{.Status}}"

logs:
	docker logs $(COTAINER_NAME)

sql:
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "SHOW search_path;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM $(DB_USER_NAME).fruits_menu;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "INSERT INTO $(DB_USER_NAME).fruits_menu (name, price) VALUES ('Peach', 200);"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "UPDATE $(DB_USER_NAME).fruits_menu SET price = 112 WHERE name = 'Orange';"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "DELETE FROM $(DB_USER_NAME).fruits_menu WHERE name = 'Peach';"

stop:
	@echo -n "+ "
	docker-compose down
	@echo -n "+ "
	sudo rm -fR $(DATA_DIR)
