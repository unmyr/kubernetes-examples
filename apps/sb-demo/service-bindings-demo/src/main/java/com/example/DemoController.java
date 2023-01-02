package com.example;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/")
public class DemoController {
	@Value("${k8s.bindings.service-bindings-demo-sb.private-key:nil}")
	private String privateKey;

	@RequestMapping(value="/", method=RequestMethod.GET)
	public ResponseEntity<?> index() {
		Map<String,Object> map = new HashMap<>();
		map.put("private-key", privateKey);
		return ResponseEntity.ok(map);
	}
}
