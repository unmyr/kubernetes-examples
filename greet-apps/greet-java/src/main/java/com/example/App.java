package com.example;

import java.util.HashMap;
import java.util.Map;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * Simple greeting application
 *
 */
@SpringBootApplication
@RestController
public class App {
  private static final String template = "Hello, %s!";

  @GetMapping("/hello/{name}")
  public Map<String, String> greeting(@PathVariable(value = "name") String name) {
    HashMap<String, String> map = new HashMap<>();
    map.put("message", String.format(template, name));
    return map;
  }

  public static void main(String[] args) {
    SpringApplication.run(App.class, args);
  }
}
