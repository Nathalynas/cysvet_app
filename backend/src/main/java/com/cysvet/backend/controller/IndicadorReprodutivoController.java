package com.cysvet.backend.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.cysvet.backend.dto.indicador.IndicadorReprodutivoResponse;
import com.cysvet.backend.service.IndicadorReprodutivoService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/indicators")
@RequiredArgsConstructor
public class IndicadorReprodutivoController {

    private final IndicadorReprodutivoService indicadorReprodutivoService;

    @GetMapping
    public List<IndicadorReprodutivoResponse> list() {
        return indicadorReprodutivoService.list();
    }

    @PostMapping("/snapshot")
    @ResponseStatus(HttpStatus.CREATED)
    public IndicadorReprodutivoResponse snapshot(
            @RequestParam(required = false) Long idPropriedade,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim
    ) {
        return indicadorReprodutivoService.snapshot(idPropriedade, dataInicio, dataFim);
    }
}
