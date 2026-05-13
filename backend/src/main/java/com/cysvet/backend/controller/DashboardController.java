package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.dashboard.DashboardResponse;
import com.cysvet.backend.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard", description = "Endpoints para consulta de indicadores consolidados do dashboard.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping
    @Operation(summary = "Consulta metricas do dashboard")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Metricas obtidas com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public DashboardResponse getMetrics(
            @RequestParam(name = "idPropriedade", required = false) Long idPropriedade,
            @RequestParam(name = "dataInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(name = "dataFim", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim
    ) {
        return dashboardService.getMetrics(idPropriedade, dataInicio, dataFim);
    }
}
