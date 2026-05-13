package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.auth.EmpresaPermitidaResponse;
import com.cysvet.backend.dto.company.UpdateCompanyRequest;
import com.cysvet.backend.service.CompanyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/companies")
@RequiredArgsConstructor
@Tag(name = "Empresas", description = "Endpoints para gerenciamento da empresa ativa do usuario autenticado.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class CompanyController {

    private final CompanyService companyService;

    @PutMapping("/active")
    @Operation(summary = "Atualiza a empresa ativa do usuario")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Empresa ativa atualizada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public EmpresaPermitidaResponse updateActiveCompany(@Valid @RequestBody UpdateCompanyRequest request) {
        return companyService.updateActiveCompany(request);
    }
}
