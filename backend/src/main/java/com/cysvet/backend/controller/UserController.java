package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.user.CreateUserRequest;
import com.cysvet.backend.dto.user.UpdateUserMembershipStatusRequest;
import com.cysvet.backend.dto.user.UpdateUserRequest;
import com.cysvet.backend.dto.user.UserResponse;
import com.cysvet.backend.service.TeamService;
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
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "Equipe", description = "Endpoints para gerenciamento da equipe da empresa ativa.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class UserController {

    private final TeamService teamService;

    @GetMapping
    @Operation(summary = "Lista os membros da empresa ativa")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Equipe listada com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Sem acesso a empresa informada")
    })
    public List<UserResponse> list() {
        return teamService.listActiveCompanyMembers();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Cria um veterinario vinculado a empresa ativa")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Veterinario criado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Apenas administradores podem criar membros")
    })
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
        return teamService.createVeterinarian(request);
    }

    @PutMapping("/{userId}")
    @Operation(summary = "Atualiza dados de um membro da empresa ativa")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Membro atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Apenas administradores podem alterar membros"),
            @ApiResponse(responseCode = "404", description = "Vinculo nao encontrado")
    })
    public UserResponse update(
            @PathVariable Long userId,
            @Valid @RequestBody UpdateUserRequest request
    ) {
        return teamService.updateMember(userId, request);
    }

    @PatchMapping("/{userId}/status")
    @Operation(summary = "Ativa ou inativa o vinculo do usuario com a empresa ativa")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Vinculo atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Apenas administradores podem alterar o vinculo"),
            @ApiResponse(responseCode = "404", description = "Vinculo nao encontrado")
    })
    public UserResponse updateStatus(
            @PathVariable Long userId,
            @Valid @RequestBody UpdateUserMembershipStatusRequest request
    ) {
        return teamService.updateMembershipStatus(userId, request);
    }

    @DeleteMapping("/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove o usuario da empresa ativa")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Membro removido com sucesso"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado"),
            @ApiResponse(responseCode = "403", description = "Apenas administradores podem remover membros"),
            @ApiResponse(responseCode = "404", description = "Vinculo nao encontrado")
    })
    public void delete(@PathVariable Long userId) {
        teamService.removeMember(userId);
    }
}
