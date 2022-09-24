SHOW search_path;
SELECT * FROM fruits_menu;
SELECT * FROM dbuser1.fruits_menu;
INSERT INTO dbuser1.fruits_menu (name, price) VALUES ('Peach', 200);
UPDATE dbuser1.fruits_menu SET price = 112 WHERE name = 'Orange';
DELETE FROM dbuser1.fruits_menu WHERE name = 'Peach';
