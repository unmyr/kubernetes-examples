\connect fruits;

DROP TABLE IF EXISTS fruits_menu CASCADE;

CREATE TABLE fruits_menu (
  id SERIAL PRIMARY KEY,
  name VARCHAR(16) UNIQUE,
  price INTEGER,
  mod_time timestamp DEFAULT current_timestamp
);

INSERT INTO fruits_menu (name, price) VALUES
  ('Apple', 100), ('Banana', 120), ('Orange', 110);
