package com.cysvet.backend.controller;

import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/actuator")
public class ObservabilityPolicyController {

    @GetMapping("/observability-policy")
    public Map<String, Object> observabilityPolicy() {
        return Map.of(
                "healthcheck", Map.of(
                        "publicPath", "/actuator/health",
                        "livenessPath", "/actuator/liveness",
                        "readinessPath", "/actuator/readiness",
                        "expectedHttpStatus", 200,
                        "expectedBodyStatus", "UP"
                ),
                "structuredLogging", Map.of(
                        "format", "key-value",
                        "correlationHeader", "X-Request-Id",
                        "fields", List.of(
                                "ts",
                                "level",
                                "app",
                                "profile",
                                "requestId",
                                "tenantId",
                                "userId",
                                "method",
                                "path",
                                "status",
                                "durationMs",
                                "logger",
                                "msg"
                        )
                ),
                "monitoring", Map.of(
                        "errors", Map.of(
                                "source", "application logs",
                                "signal", "level=ERROR or status>=500",
                                "window", "5m"
                        ),
                        "availability", Map.of(
                                "source", "health endpoints",
                                "signal", "health, liveness and readiness must remain UP",
                                "window", "1m"
                        ),
                        "login", Map.of(
                                "source", "request logs for /api/auth/login",
                                "signal", "status=400 or status=401",
                                "window", "5m"
                        ),
                        "migration", Map.of(
                                "source", "startup logs and readiness endpoint",
                                "signal", "Flyway failure or readiness not UP after deploy",
                                "window", "deploy window"
                        )
                ),
                "alerts", List.of(
                        Map.of(
                                "name", "backend-unavailable",
                                "severity", "critical",
                                "trigger", "health or readiness not UP for 2 consecutive checks / 2 minutes"
                        ),
                        Map.of(
                                "name", "database-unavailable",
                                "severity", "critical",
                                "trigger", "readiness DOWN or db contributor DOWN for 1 minute"
                        ),
                        Map.of(
                                "name", "login-failure-spike",
                                "severity", "warning",
                                "trigger", "10 or more failures on /api/auth/login within 5 minutes"
                        ),
                        Map.of(
                                "name", "migration-failed",
                                "severity", "critical",
                                "trigger", "Flyway migration failure or backend not healthy within 5 minutes after deploy"
                        )
                )
        );
    }
}
