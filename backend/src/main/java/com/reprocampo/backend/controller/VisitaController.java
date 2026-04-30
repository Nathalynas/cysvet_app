package com.reprocampo.backend.controller;

import java.util.List;

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

import com.reprocampo.backend.dto.visita.VisitaRequest;
import com.reprocampo.backend.dto.visita.VisitaResponse;
import com.reprocampo.backend.service.VisitaService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/visits")
@RequiredArgsConstructor
public class VisitaController {

    private final VisitaService visitService;

    @GetMapping
    public List<VisitaResponse> list(@RequestParam(required = false) Long idPropriedade) {
        return visitService.list(idPropriedade);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public VisitaResponse create(@Valid @RequestBody VisitaRequest request) {
        return visitService.create(request);
    }

    @PutMapping("/{id}")
    public VisitaResponse update(@PathVariable Long id, @Valid @RequestBody VisitaRequest request) {
        return visitService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        visitService.delete(id);
    }
}
