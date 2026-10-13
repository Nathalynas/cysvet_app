package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.superadmin.ClientCompanyResponse;
import com.cysvet.backend.dto.superadmin.CreateClientCompanyRequest;
import com.cysvet.backend.dto.superadmin.CreateClientCompanyResponse;
import com.cysvet.backend.dto.superadmin.ResendAccessResponse;
import com.cysvet.backend.dto.superadmin.UpdateClientCompanyStatusRequest;
import com.cysvet.backend.service.SuperAdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/super/companies")
@RequiredArgsConstructor
@Tag(name = "Super usuario", description = "Cadastro e gerenciamento de empresas clientes pelo super usuario.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class SuperAdminController {

    private final SuperAdminService superAdminService;

    @GetMapping
    @Operation(summary = "Lista todas as empresas clientes")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Empresas listadas com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Acesso negado")
    })
    public List<ClientCompanyResponse> list() {
        return superAdminService.list();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cadastra empresa cliente e envia a senha provisoria ao responsavel")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Empresa cadastrada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos ou e-mail ja cadastrado"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Acesso negado")
    })
    public CreateClientCompanyResponse create(@Valid @RequestBody CreateClientCompanyRequest request) {
        return superAdminService.create(request);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Desativa ou reativa uma empresa cliente")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Situacao atualizada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "404", description = "Empresa nao encontrada")
    })
    public ClientCompanyResponse updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateClientCompanyStatusRequest request
    ) {
        return superAdminService.updateStatus(id, request.active());
    }

    @PostMapping("/{id}/resend-access")
    @Operation(summary = "Gera nova senha provisoria e reenvia o acesso ao responsavel")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Acesso reenviado"),
            @ApiResponse(responseCode = "400", description = "Empresa sem responsavel"),
            @ApiResponse(responseCode = "404", description = "Empresa nao encontrada")
    })
    public ResendAccessResponse resendAccess(@PathVariable Long id) {
        return superAdminService.resendAccess(id);
    }
}
