package com.example;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.jdbc.JdbcTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Sql({"/schema.sql", "/test-data.sql"})
public class FruitStoreControllerTest {
	@Autowired
	private JdbcTemplate jdbcTemplate;
	@Autowired
	private MockMvc mockMvc;

	@AfterEach
	public void tearDown() {
		JdbcTestUtils.deleteFromTables(jdbcTemplate, "fruits_menu");
	}

	@Test
	public void findAll() throws Exception {
		this.mockMvc.perform(
			MockMvcRequestBuilders.get(
				"/api/"
			).contentType(
				MediaType.APPLICATION_JSON
			).accept(
				MediaType.APPLICATION_JSON
			)
		).andDo(
			print()
		).andExpect(
			status().isOk()
		).andExpect(
			MockMvcResultMatchers.jsonPath("$.length()").value(3)
		).andExpect(
			MockMvcResultMatchers.jsonPath("$[*].name").value(
				containsInAnyOrder("Apple", "Banana", "Orange")
			)
		).andExpect(
			MockMvcResultMatchers.jsonPath("$[*].price").value(containsInAnyOrder(100, 120, 110))
		).andExpect(
			MockMvcResultMatchers.jsonPath("$.[?(@.name == \"Apple\" && @.price == 100)]").exists()
		).andExpect(
			MockMvcResultMatchers.jsonPath("$.[?(@.name == \"Banana\" && @.price == 120)]").exists()
		).andExpect(
			MockMvcResultMatchers.jsonPath("$.[?(@.name == \"Orange\" && @.price == 110)]").exists()
		);
	}
}
