package com.example.workshop.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class WelcomeController {

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of(
            "message", "Spring Boot is running inside the Dev Container",
            "database", "PostgreSQL is configured through environment variables"
        );
    }
}
