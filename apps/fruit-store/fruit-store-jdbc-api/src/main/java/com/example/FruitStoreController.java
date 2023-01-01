package com.example;

import java.util.NoSuchElementException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class FruitStoreController {
	@Autowired
	FruitStoreService service;

	@RequestMapping(value="/", method=RequestMethod.GET)
	public ResponseEntity<?> list(
	  @RequestParam(name = "name", required = false) String fruitName
	) {
	  if (fruitName == null) {
		return ResponseEntity.ok(service.findAll());
	  }
  
	  try {
		return ResponseEntity.ok(
		  service.findOneByName(fruitName).get()
		);
	  } catch(NoSuchElementException ex) {
		return ResponseEntity.notFound().build();
	  }
	}
}
