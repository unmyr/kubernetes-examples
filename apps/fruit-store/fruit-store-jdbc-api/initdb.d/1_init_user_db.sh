#!/bin/bash
DB_NAME="fruits"

echo "DB_NAME='${DB_NAME}', POSTGRES_USER='${POSTGRES_USER}'"
psql -U ${POSTGRES_USER} <<EOF
CREATE DATABASE ${DB_NAME};

\connect ${DB_NAME};
CREATE ROLE ${ADDITIONAL_USER} WITH LOGIN PASSWORD '${ADDITIONAL_PASSWORD}';
CREATE SCHEMA IF NOT EXISTS ${ADDITIONAL_USER};
GRANT USAGE ON SCHEMA ${ADDITIONAL_USER} TO ${ADDITIONAL_USER};
EOF