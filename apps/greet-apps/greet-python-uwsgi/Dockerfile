FROM python:3.8-buster as builder
LABEL stage=builder
WORKDIR /build/dist

COPY requirements.txt /build
RUN python3 -m venv /build \
 && . /build/bin/activate \
 && python -m pip install --upgrade pip \
 && python -m pip install -r /build/requirements.txt --target /build/dist
COPY ./src /build/dist

FROM python:3.8-slim-buster as runner
WORKDIR /opt/app
COPY --from=builder /build/dist /opt/app
RUN set -eux; \
 apt-get update; \
 apt-get install -y --no-install-recommends libxml2
EXPOSE 8080
ENTRYPOINT ["/opt/app/bin/uwsgi", "--ini", "/opt/app/app.ini"]
