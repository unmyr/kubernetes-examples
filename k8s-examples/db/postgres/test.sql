SHOW search_path;
SELECT * FROM fruits_menu;
SELECT * FROM db_user1.fruits_menu;
INSERT INTO db_user1.fruits_menu (name, price) VALUES ('Peach', 200);
UPDATE db_user1.fruits_menu SET price = 112 WHERE name = 'Orange';
DELETE FROM db_user1.fruits_menu WHERE name = 'Peach';
