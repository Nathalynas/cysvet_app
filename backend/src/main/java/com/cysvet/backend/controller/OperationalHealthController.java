package com.cysvet.backend.controller;

import java.sql.Connection;
import java.time.Instant;
import java.util.Map;
import javax.sql.DataSource;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/actuator")
@RequiredArgsConstructor
public class OperationalHealthController {

    private final DataSource dataSource;

    @GetMapping("/liveness")
    public Map<String, Object> liveness() {
        return Map.of(
                "status", "UP",
                "timestamp", Instant.now(),
                "checks", Map.of("application", "UP")
        );
    }

    @GetMapping("/readiness")
    public Map<String, Object> readiness() {
        try (Connection connection = dataSource.getConnection()) {
            boolean valid = connection.isValid(2);
            return Map.of(
                    "status", valid ? "UP" : "DOWN",
                    "timestamp", Instant.now(),
                    "checks", Map.of("database", valid ? "UP" : "DOWN")
            );
        } catch (Exception exception) {
            return Map.of(
                    "status", "DOWN",
                    "timestamp", Instant.now(),
                    "checks", Map.of("database", "DOWN"),
                    "message", exception.getMessage()
            );
        }
    }
}
