package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.visita.VisitaRequest;
import com.cysvet.backend.dto.visita.VisitaResponse;
import com.cysvet.backend.service.VisitaService;
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
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/visits")
@RequiredArgsConstructor
@Tag(name = "Visitas", description = "Endpoints para gerenciamento das visitas tecnicas.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class VisitaController {

    private final VisitaService visitService;

    @GetMapping
    @Operation(summary = "Lista visitas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Visitas listadas com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public List<VisitaResponse> list(@RequestParam(name = "idPropriedade", required = false) Long idPropriedade) {
        return visitService.list(idPropriedade);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cadastra uma visita")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Visita cadastrada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public VisitaResponse create(@Valid @RequestBody VisitaRequest request) {
        return visitService.create(request);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualiza uma visita")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Visita atualizada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Visita nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public VisitaResponse update(@PathVariable("id") Long id, @Valid @RequestBody VisitaRequest request) {
        return visitService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove uma visita")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Visita removida com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Visita nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public void delete(@PathVariable("id") Long id) {
        visitService.delete(id);
    }
}
