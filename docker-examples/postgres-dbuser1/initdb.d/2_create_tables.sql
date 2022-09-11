\connect fruits;
\conninfo

SET SCHEMA 'dbuser1';

CREATE TABLE fruits_menu (
  id SERIAL PRIMARY KEY,
  name VARCHAR(16) UNIQUE,
  price INTEGER,
  mod_time timestamp DEFAULT current_timestamp
);

GRANT SELECT,INSERT,UPDATE,DELETE ON fruits_menu TO dbuser1;
GRANT USAGE ON SEQUENCE fruits_menu_id_seq TO dbuser1;

INSERT INTO fruits_menu (name, price) VALUES
  ('Apple', 100), ('Banana', 120), ('Orange', 110);

\l
\dt dbuser1.*
\d fruits_menu
\dn+
