up:
	-docker compose up --build -d
	-docker ps -a --filter name=greet-python
	-docker logs greet-python
stat:
	-docker ps -a --filter name=greet-python
	-docker logs greet-python
down:
	-docker compose down
	-docker ps -a --filter "name=greet-python" --format '{{.ID}}' | xargs -r docker rm
	-docker image ls --filter "reference=greet-python*" --format '{{.ID}}' | xargs -r docker rmi
