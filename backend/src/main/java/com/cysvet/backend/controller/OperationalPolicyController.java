package com.cysvet.backend.controller;

import com.cysvet.backend.tenant.TenantConstants;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/actuator")
public class OperationalPolicyController {

    @GetMapping("/tenant-policy")
    public Map<String, Object> tenantPolicy() {
        return Map.of(
                "headerName", TenantConstants.HEADER_NAME,
                "requiredOnAuthenticatedRequests", true,
                "membershipValidation", "usuario precisa ter vinculo ativo com a empresa informada"
        );
    }
}
