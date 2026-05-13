package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
@Tag(name = "Relatorios", description = "Endpoints para exportacao de relatorios em PDF e Excel.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/property/{idPropriedade}/pdf")
    @Operation(summary = "Exporta relatorio tecnico da propriedade em PDF")
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Arquivo PDF gerado com sucesso",
                    content = @Content(mediaType = MediaType.APPLICATION_PDF_VALUE, schema = @Schema(type = "string", format = "binary"))
            ),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Propriedade nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public ResponseEntity<byte[]> exportPdf(
            @PathVariable("idPropriedade") Long idPropriedade,
            @RequestParam(name = "dataInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(name = "dataFim", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim
    ) {
        byte[] file = reportService.generatePdf(idPropriedade, dataInicio, dataFim);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=relatorio-tecnico.pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(file);
    }

    @GetMapping("/visit/{visitId}/pdf")
    @Operation(summary = "Exporta relatorio de visita em PDF")
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Arquivo PDF gerado com sucesso",
                    content = @Content(mediaType = MediaType.APPLICATION_PDF_VALUE, schema = @Schema(type = "string", format = "binary"))
            ),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Visita nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public ResponseEntity<byte[]> exportVisitPdf(@PathVariable("visitId") Long visitId) {
        byte[] file = reportService.generateVisitPdf(visitId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=relatorio-visita.pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(file);
    }

    @GetMapping("/property/{idPropriedade}/xlsx")
    @Operation(summary = "Exporta relatorio tecnico da propriedade em Excel")
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Arquivo Excel gerado com sucesso",
                    content = @Content(
                            mediaType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                            schema = @Schema(type = "string", format = "binary")
                    )
            ),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Propriedade nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public ResponseEntity<byte[]> exportExcel(
            @PathVariable("idPropriedade") Long idPropriedade,
            @RequestParam(name = "dataInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(name = "dataFim", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim
    ) {
        byte[] file = reportService.generateExcel(idPropriedade, dataInicio, dataFim);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=relatorio-tecnico.xlsx")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(file);
    }

    @GetMapping("/visit/{visitId}/xlsx")
    @Operation(summary = "Exporta relatorio de visita em Excel")
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Arquivo Excel gerado com sucesso",
                    content = @Content(
                            mediaType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                            schema = @Schema(type = "string", format = "binary")
                    )
            ),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Visita nao encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public ResponseEntity<byte[]> exportVisitExcel(@PathVariable("visitId") Long visitId) {
        byte[] file = reportService.generateVisitExcel(visitId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=relatorio-visita.xlsx")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(file);
    }
}
