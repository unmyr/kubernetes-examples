package com.example;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class FruitStoreService {
	private JdbcTemplate jdbcTemplate;

	@Autowired
	public FruitStoreService(JdbcTemplate jdbcTemplate) {
		this.jdbcTemplate = jdbcTemplate;
	}

	public List<FruitsMenu> findAll() {
		return jdbcTemplate.query(
		  "SELECT id, name, price, quantity, mod_time FROM fruits_menu",
		  new FruitsMenuRowMapper()
		);
	}

	public Optional<FruitsMenu> findOneByName(String fruitName) {
		return jdbcTemplate.query(
		  "SELECT id, name, price, quantity, mod_time FROM fruits_menu WHERE name=?",
		  new FruitsMenuRowMapper(),
		  fruitName
		).stream().findFirst();
	}
}
