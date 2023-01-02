#!/bin/bash
DB_NAME="fruits"

echo "DB_NAME='${DB_NAME}', POSTGRES_USER='${POSTGRES_USER}', ADDITIONAL_USER='${ADDITIONAL_USER}'"
psql -U ${POSTGRES_USER} <<EOF
\connect ${DB_NAME};
\conninfo

-- SET SCHEMA '${ADDITIONAL_USER}';
SET search_path TO '${ADDITIONAL_USER}';
SELECT current_schema;
CREATE TABLE fruits_menu (
  id SERIAL PRIMARY KEY,
  name VARCHAR(16) UNIQUE,
  price INTEGER,
  quantity INTEGER DEFAULT 0,
  mod_time timestamp DEFAULT current_timestamp
);

GRANT SELECT,INSERT,UPDATE,DELETE ON fruits_menu TO ${ADDITIONAL_USER};
GRANT USAGE ON SEQUENCE fruits_menu_id_seq TO ${ADDITIONAL_USER};

INSERT INTO fruits_menu (name, price, quantity) VALUES
  ('Apple', 100, 10), ('Banana', 120, 1), ('Orange', 110, 0);

\l
\dt ${ADDITIONAL_USER}.*
\d fruits_menu
\dn+
EOF