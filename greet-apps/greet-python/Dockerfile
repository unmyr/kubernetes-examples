FROM python:3.8-buster as builder

WORKDIR /opt/app

RUN mkdir /dist
COPY requirements.txt /opt/app
RUN python -m pip install -r /opt/app/requirements.txt --target /dist
COPY ./src /dist

FROM python:3.8-slim-buster as runner
COPY --from=builder /dist .
EXPOSE 8080
ENTRYPOINT ["python", "./server.py"]
