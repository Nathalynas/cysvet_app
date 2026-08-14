package com.cysvet.backend.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class OperationalReadinessIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void actuatorHealthShouldBePublic() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void actuatorLivenessAndReadinessShouldBePublic() throws Exception {
        mockMvc.perform(get("/actuator/liveness"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.status").value("UP"));

        mockMvc.perform(get("/actuator/readiness"))
                .andExpect(status().isOk())
                .andExpect(header().exists("X-Request-Id"))
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void tenantPolicyEndpointShouldExposeTenantRules() throws Exception {
        mockMvc.perform(get("/actuator/tenant-policy"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.headerName").value("empresaid"))
                .andExpect(jsonPath("$.requiredOnAuthenticatedRequests").value(true));
    }

    @Test
    void observabilityPolicyEndpointShouldExposeOperationalContract() throws Exception {
        mockMvc.perform(get("/actuator/observability-policy"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.healthcheck.publicPath").value("/actuator/health"))
                .andExpect(jsonPath("$.structuredLogging.correlationHeader").value("X-Request-Id"))
                .andExpect(jsonPath("$.alerts[0].name").value("backend-unavailable"));
    }

    @Test
    void corsShouldAllowConfiguredOrigins() throws Exception {
        mockMvc.perform(options("/actuator/health")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));
    }

    @Test
    void corsShouldAllowFlutterWebDynamicPortInDevelopment() throws Exception {
        mockMvc.perform(options("/api/auth/login")
                        .header("Origin", "http://localhost:53389")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:53389"));
    }
}
