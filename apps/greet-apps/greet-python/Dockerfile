FROM python:3.8-buster as builder

WORKDIR /opt/app/dist

COPY requirements.txt /opt/app
RUN python3 -m venv /opt/app \
 && . /opt/app/bin/activate \
 && python -m pip install --upgrade pip \
 && python -m pip install -r /opt/app/requirements.txt --target /opt/app/dist
COPY ./src /opt/app/dist

FROM python:3.8-slim-buster as runner
COPY --from=builder /opt/app/dist .
EXPOSE 8080
ENTRYPOINT ["python", "./server.py"]
