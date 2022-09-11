-- DROP SCHEMA IF EXISTS dbuser1 CASCADE;
\connect fruits;
\conninfo

SET SCHEMA 'dbuser1';
\conninfo
SELECT current_database();

DROP TABLE IF EXISTS fruits_menu CASCADE;

CREATE TABLE fruits_menu (
  id SERIAL PRIMARY KEY,
  name VARCHAR(16) UNIQUE,
  price INTEGER,
  mod_time timestamp DEFAULT current_timestamp
);

GRANT SELECT,INSERT,UPDATE,DELETE ON fruits_menu TO dbuser1;
GRANT USAGE ON SEQUENCE fruits_menu_id_seq TO dbuser1;

ALTER USER dbuser1 SET search_path TO 'dbuser1, pg_catalog';
\l
\d fruits_menu
\dn+

INSERT INTO fruits_menu (name, price) VALUES
  ('Apple', 100), ('Banana', 120), ('Orange', 110);
