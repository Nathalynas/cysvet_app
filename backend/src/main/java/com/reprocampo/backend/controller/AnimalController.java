package com.reprocampo.backend.controller;

import com.reprocampo.backend.dto.animal.AnimalRequest;
import com.reprocampo.backend.dto.animal.AnimalResponse;
import com.reprocampo.backend.service.AnimalService;
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
@RequestMapping("/api/animals")
@RequiredArgsConstructor
public class AnimalController {

    private final AnimalService animalService;

    @GetMapping
    public List<AnimalResponse> list(@RequestParam(required = false) Long idPropriedade) {
        return animalService.list(idPropriedade);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AnimalResponse create(@Valid @RequestBody AnimalRequest request) {
        return animalService.create(request);
    }

    @PutMapping("/{id}")
    public AnimalResponse update(@PathVariable Long id, @Valid @RequestBody AnimalRequest request) {
        return animalService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        animalService.delete(id);
    }
}
