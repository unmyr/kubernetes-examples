package com.example;
import java.sql.Timestamp;

import org.springframework.data.annotation.Id;

public class FruitsMenu {
	@Id
	private int id;
 	private String name;
	private int price;
	private int quantity;
	private Timestamp modTime;

	public FruitsMenu(int id, String name, int price, int quantity, Timestamp modTime) {
		this.id = id;
		this.name = name;
		this.price = price;
		this.modTime = modTime;
	}

	public Integer getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getPrice() {
		return price;
	}

	public void setPrice(int price) {
		this.price = price;
	}

	public int getQuantity() {
		return quantity;
	}
	
	public void setQuantity(int quantity) {
		this.quantity = quantity;
	}

	public Timestamp getModTime() {
		return modTime;
	}

	public void setModTime(Timestamp modTime) {
		this.modTime = modTime;
	}
}