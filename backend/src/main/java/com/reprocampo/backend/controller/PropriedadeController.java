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
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.reprocampo.backend.dto.propriedade.PropriedadeRequest;
import com.reprocampo.backend.dto.propriedade.PropriedadeResponse;
import com.reprocampo.backend.service.PropriedadeService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/properties")
@RequiredArgsConstructor
public class PropriedadeController {

    private final PropriedadeService propriedadeService;

    @GetMapping
    public List<PropriedadeResponse> list() {
        return propriedadeService.list();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PropriedadeResponse create(@Valid @RequestBody PropriedadeRequest request) {
        return propriedadeService.create(request);
    }

    @PutMapping("/{id}")
    public PropriedadeResponse update(@PathVariable Long id, @Valid @RequestBody PropriedadeRequest request) {
        return propriedadeService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        propriedadeService.delete(id);
    }
}
