package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.sync.PullSyncResponse;
import com.cysvet.backend.dto.sync.SyncRequest;
import com.cysvet.backend.dto.sync.SyncResponse;
import com.cysvet.backend.service.SyncService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
@Tag(name = "Sincronizacao", description = "Endpoints para envio e obtencao de dados de sincronizacao offline.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class SyncController {

    private final SyncService syncService;

    @PostMapping
    @Operation(summary = "Processa uma requisicao de sincronizacao")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Sincronizacao processada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Payload invalido"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public SyncResponse sync(@Valid @RequestBody SyncRequest request) {
        return syncService.sync(request);
    }

    @GetMapping("/pull")
    @Operation(summary = "Busca atualizacoes para sincronizacao")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Atualizacoes obtidas com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public PullSyncResponse pull(
            @RequestParam(name = "since", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant since
    ) {
        return syncService.pull(since);
    }
}
