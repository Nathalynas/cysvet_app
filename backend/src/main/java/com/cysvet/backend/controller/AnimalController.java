package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.animal.AnimalRequest;
import com.cysvet.backend.dto.animal.AnimalResponse;
import com.cysvet.backend.dto.animal.AnimalStatusRequest;
import com.cysvet.backend.service.AnimalService;
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
@RequestMapping("/api/animals")
@RequiredArgsConstructor
@Tag(name = "Animais", description = "Endpoints para gerenciar os animais das propriedades.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class AnimalController {

    private final AnimalService animalService;

    @GetMapping
    @Operation(summary = "Lista animais")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Animais listados com sucesso"),
            @ApiResponse(responseCode = "400", description = "Parametros invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public List<AnimalResponse> list(
            @RequestParam(name = "idPropriedade", required = false) Long idPropriedade,
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "status", required = false) String status
    ) {
        return animalService.list(idPropriedade, search, status);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cadastra um animal")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Animal cadastrado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public AnimalResponse create(@Valid @RequestBody AnimalRequest request) {
        return animalService.create(request);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualiza um animal")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Animal atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Animal nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public AnimalResponse update(@PathVariable("id") Long id, @Valid @RequestBody AnimalRequest request) {
        return animalService.update(id, request);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Atualiza o status de um animal")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Status do animal atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Animal nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public AnimalResponse updateStatus(@PathVariable("id") Long id, @Valid @RequestBody AnimalStatusRequest request) {
        return animalService.updateStatus(id, request.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove um animal")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Animal removido com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "404", description = "Animal nao encontrado"),
            @ApiResponse(responseCode = "500", description = "Erro interno no servidor")
    })
    public void delete(@PathVariable("id") Long id) {
        animalService.delete(id);
    }
}
