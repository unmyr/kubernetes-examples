package com.example;

import java.sql.ResultSet;
import java.sql.SQLException;

import org.springframework.jdbc.core.RowMapper;
import org.springframework.lang.Nullable;

public class FruitsMenuRowMapper implements RowMapper<FruitsMenu> {

  @Override
  @Nullable
  public FruitsMenu mapRow(ResultSet rs, int rowNum) throws SQLException {
    return new FruitsMenu(
      rs.getInt("id"),
      rs.getString("name"),
      rs.getInt("price"),
	  rs.getInt("quantity"),
      rs.getTimestamp("mod_time")
    );
  }
}