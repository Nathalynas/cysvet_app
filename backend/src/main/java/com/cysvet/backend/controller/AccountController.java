package com.cysvet.backend.controller;

import com.cysvet.backend.config.SwaggerConfig;
import com.cysvet.backend.dto.account.AccountPreferences;
import com.cysvet.backend.dto.account.ChangePasswordRequest;
import com.cysvet.backend.service.AuthService;
import com.cysvet.backend.service.PreferenciasUsuarioService;
import com.cysvet.backend.service.UsuarioAutenticadoProvider;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/account")
@RequiredArgsConstructor
@Tag(name = "Conta", description = "Operacoes da conta do usuario autenticado.")
@SecurityRequirement(name = SwaggerConfig.BEARER_SCHEME)
public class AccountController {

    private final AuthService authService;
    private final UsuarioAutenticadoProvider usuarioAutenticadoProvider;
    private final PreferenciasUsuarioService preferenciasUsuarioService;

    @PostMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Define a nova senha quando a troca e obrigatoria")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Senha alterada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Senha invalida ou troca nao solicitada"),
            @ApiResponse(responseCode = "401", description = "Nao autorizado")
    })
    public void changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        authService.changeRequiredPassword(usuarioAutenticadoProvider.getCurrentUser().getId(), request.newPassword());
    }

    @GetMapping("/preferences")
    @Operation(summary = "Preferencias do usuario (atalhos de situacao reprodutiva da visita)")
    public AccountPreferences preferences() {
        return preferenciasUsuarioService.get(usuarioAutenticadoProvider.getCurrentUser());
    }

    @PutMapping("/preferences")
    @Operation(summary = "Atualiza as preferencias do usuario; atalhos nulos voltam ao padrao")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Preferencias salvas"),
            @ApiResponse(responseCode = "400", description = "Situacao invalida, vazia ou atalhos demais")
    })
    public AccountPreferences updatePreferences(@RequestBody AccountPreferences request) {
        return preferenciasUsuarioService.update(usuarioAutenticadoProvider.getCurrentUser(), request);
    }
}
