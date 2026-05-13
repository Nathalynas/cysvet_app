package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.evento.EventoReprodutivoRequest;
import com.cysvet.backend.dto.evento.EventoReprodutivoResponse;
import com.cysvet.backend.service.EventoReprodutivoService;
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
@RequestMapping("/api/events")
@RequiredArgsConstructor
@Tag(name = "Eventos Reprodutivos", description = "Endpoints para gerenciamento de eventos reprodutivos dos animais.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class EventoReprodutivoController {

    private final EventoReprodutivoService eventoReprodutivoService;

    @GetMapping
    @Operation(summary = "Lista eventos reprodutivos")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Eventos listados com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public List<EventoReprodutivoResponse> list(
            @RequestParam(name = "idPropriedade", required = false) Long idPropriedade,
            @RequestParam(name = "idAnimal", required = false) Long idAnimal
    ) {
        return eventoReprodutivoService.list(idPropriedade, idAnimal);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cadastra um evento reprodutivo")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Evento cadastrado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public EventoReprodutivoResponse create(@Valid @RequestBody EventoReprodutivoRequest request) {
        return eventoReprodutivoService.create(request);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualiza um evento reprodutivo")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Evento atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Evento nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public EventoReprodutivoResponse update(@PathVariable("id") Long id, @Valid @RequestBody EventoReprodutivoRequest request) {
        return eventoReprodutivoService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove um evento reprodutivo")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Evento removido com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Evento nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public void delete(@PathVariable("id") Long id) {
        eventoReprodutivoService.delete(id);
    }
}
