package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.propriedade.PropriedadeRequest;
import com.cysvet.backend.dto.propriedade.PropriedadeResponse;
import com.cysvet.backend.dto.propriedade.PropriedadeStatusRequest;
import com.cysvet.backend.service.PropriedadeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/properties")
@RequiredArgsConstructor
@Tag(name = "Propriedades", description = "Endpoints para gerenciamento das propriedades rurais.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class PropriedadeController {

    private final PropriedadeService propriedadeService;

    @GetMapping
    @Operation(summary = "Lista propriedades")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Propriedades listadas com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public List<PropriedadeResponse> list(
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "status", required = false) String status
    ) {
        return propriedadeService.list(search, status);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cadastra uma propriedade")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Propriedade cadastrada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public PropriedadeResponse create(@Valid @RequestBody PropriedadeRequest request) {
        return propriedadeService.create(request);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualiza uma propriedade")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Propriedade atualizada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Propriedade nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public PropriedadeResponse update(@PathVariable("id") Long id, @Valid @RequestBody PropriedadeRequest request) {
        return propriedadeService.update(id, request);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Atualiza o status de uma propriedade")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Status da propriedade atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Propriedade nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public PropriedadeResponse updateStatus(@PathVariable("id") Long id, @Valid @RequestBody PropriedadeStatusRequest request) {
        return propriedadeService.updateStatus(id, request.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove uma propriedade")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Propriedade removida com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Propriedade nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public void delete(@PathVariable("id") Long id) {
        propriedadeService.delete(id);
    }
}
