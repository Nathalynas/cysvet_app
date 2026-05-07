package com.cysvet.backend.controller;

import com.cysvet.backend.dto.auth.EmpresaPermitidaResponse;
import com.cysvet.backend.dto.company.UpdateCompanyRequest;
import com.cysvet.backend.service.CompanyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/companies")
@RequiredArgsConstructor
public class CompanyController {

    private final CompanyService companyService;

    @PutMapping("/active")
    public EmpresaPermitidaResponse updateActiveCompany(@Valid @RequestBody UpdateCompanyRequest request) {
        return companyService.updateActiveCompany(request);
    }
}
