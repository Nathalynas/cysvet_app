package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.indicador.IndicadorReprodutivoResponse;
import com.cysvet.backend.service.IndicadorReprodutivoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/indicators")
@RequiredArgsConstructor
@Tag(name = "Indicadores Reprodutivos", description = "Endpoints para consulta e geracao de snapshots de indicadores reprodutivos.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class IndicadorReprodutivoController {

    private final IndicadorReprodutivoService indicadorReprodutivoService;

    @GetMapping
    @Operation(summary = "Lista indicadores reprodutivos")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Indicadores listados com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public List<IndicadorReprodutivoResponse> list() {
        return indicadorReprodutivoService.list();
    }

    @PostMapping("/snapshot")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Gera um snapshot de indicadores reprodutivos")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Snapshot gerado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public IndicadorReprodutivoResponse snapshot(
            @RequestParam(name = "idPropriedade", required = false) Long idPropriedade,
            @RequestParam(name = "dataInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(name = "dataFim", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim
    ) {
        return indicadorReprodutivoService.snapshot(idPropriedade, dataInicio, dataFim);
    }
}
