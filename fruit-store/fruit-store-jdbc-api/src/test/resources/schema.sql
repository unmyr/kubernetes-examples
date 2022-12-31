CREATE TABLE IF NOT EXISTS fruits_menu (
  id SERIAL PRIMARY KEY,
  name VARCHAR(16) UNIQUE,
  price INTEGER,
  quantity INTEGER DEFAULT 0,
  mod_time timestamp DEFAULT current_timestamp
);
