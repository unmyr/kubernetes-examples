COTAINER_NAME=postgres-noschema
DATA_DIR=/var/tmp/postgres-noschema/
DB_USER_NAME=postgres
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
	../bin/psql_wait_table_created postgres $(DB_NAME) fruits_menu
	@echo -n "+ "
	docker ps -a --filter "name=postgres" --format "{{.State}} {{.Status}}"
	@echo -n "+ "
	docker logs $(COTAINER_NAME)
	@echo -n "+ "
	psql -h localhost -U postgres -d fruits -c "SELECT * FROM fruits_menu;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "SHOW search_path;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "SELECT * FROM public.fruits_menu;"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "INSERT INTO public.fruits_menu (name, price) VALUES ('Peach', 200);"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "UPDATE public.fruits_menu SET price = 112 WHERE name = 'Orange';"
	@echo -n "+ "
	psql -h localhost -U $(DB_USER_NAME) -d fruits -c "DELETE FROM public.fruits_menu WHERE name = 'Peach';"

status:
	@echo -n "+ "
	docker ps -a --filter "name=postgres" --format "{{.State}} {{.Status}}"

stop:
	@echo -n "+ "
	docker-compose down
	@echo -n "+ "
	sudo rm -fR $(DATA_DIR)

