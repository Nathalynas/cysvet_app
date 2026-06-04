package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.lote.LoteRequest;
import com.cysvet.backend.dto.lote.LoteResponse;
import com.cysvet.backend.dto.lote.LoteStatusRequest;
import com.cysvet.backend.service.LoteService;
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
@RequestMapping("/api/lots")
@RequiredArgsConstructor
@Tag(name = "Lotes", description = "Endpoints para organizacao dos lotes dentro das propriedades.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class LoteController {

    private final LoteService loteService;

    @GetMapping
    @Operation(summary = "Lista lotes")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lotes listados com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public List<LoteResponse> list(
            @RequestParam(name = "idPropriedade", required = false) Long idPropriedade,
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "status", required = false) String status
    ) {
        return loteService.list(idPropriedade, search, status);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cadastra um lote")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Lote cadastrado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public LoteResponse create(@Valid @RequestBody LoteRequest request) {
        return loteService.create(request);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualiza um lote")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lote atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Lote nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public LoteResponse update(@PathVariable("id") Long id, @Valid @RequestBody LoteRequest request) {
        return loteService.update(id, request);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Atualiza o status de um lote")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Status do lote atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Lote nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public LoteResponse updateStatus(@PathVariable("id") Long id, @Valid @RequestBody LoteStatusRequest request) {
        return loteService.updateStatus(id, request.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove um lote")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Lote removido com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Lote nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public void delete(@PathVariable("id") Long id) {
        loteService.delete(id);
    }
}
