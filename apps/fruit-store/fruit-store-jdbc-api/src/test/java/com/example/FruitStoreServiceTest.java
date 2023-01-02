package com.example;

import java.util.List;

import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.jdbc.DataJdbcTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;

@DataJdbcTest
@Sql({"/schema.sql", "/test-data.sql"})
public class FruitStoreServiceTest {
	private FruitStoreService service;

	@Autowired
	FruitStoreServiceTest(JdbcTemplate jdbcTemplate) {
		this.service = new FruitStoreService(jdbcTemplate);
	}
	
	@Test
	public void findAll() {
		List<FruitsMenu> fruits = service.findAll();
		Assertions.assertThat(fruits.size()).isEqualTo(3);
		Assertions.assertThat(
			fruits.get(0).getModTime().toString()
		).isEqualTo("1999-12-31 23:59:59.999");
	}
}
