package com.cysvet.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.dto.auth.RegisterRequest;
import com.cysvet.backend.dto.auth.TokenRefreshRequest;
import com.cysvet.backend.entity.TokenAtualizacao;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.TokenAtualizacaoRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
class AuthServiceIntegrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private TokenAtualizacaoRepository tokenAtualizacaoRepository;

    @Test
    void registerShouldPersistUserWithGeneratedIdBeforeSavingRefreshToken() {
        AuthResponse response = authService.register(
                new RegisterRequest("Teste", "teste.auth.service@example.com", "123456")
        );

        assertNotNull(response.user());
        assertNotNull(response.user().id());
        assertNotNull(response.refreshToken());

        Usuario usuario = usuarioRepository.findByEmail("teste.auth.service@example.com")
                .orElseThrow(() -> new AssertionError("Usuario nao persistido"));
        assertNotNull(usuario.getId());

        TokenAtualizacao token = tokenAtualizacaoRepository.findByTokenAndRevogadoFalse(response.refreshToken())
                .orElseThrow(() -> new AssertionError("Token nao persistido"));
        assertNotNull(token.getId());
        assertNotNull(token.getUsuario());
        assertNotNull(token.getUsuario().getId());
        assertEquals(usuario.getId(), token.getUsuario().getId());
        assertNotNull(response.sessionPolicy());
        assertNotNull(response.sessionPolicy().accessTokenExpiresAt());
        assertNotNull(response.sessionPolicy().refreshTokenExpiresAt());
        assertTrue(response.sessionPolicy().refreshTokenExpiresAt().isAfter(response.sessionPolicy().accessTokenExpiresAt()));
    }

    @Test
    void refreshShouldRotateTokensAndExposeOfflineSessionPolicy() {
        AuthResponse registered = authService.register(
                new RegisterRequest("Refresh Teste", "teste.auth.refresh@example.com", "123456")
        );

        AuthResponse refreshed = authService.refresh(new TokenRefreshRequest(registered.refreshToken()));

        assertNotEquals(registered.refreshToken(), refreshed.refreshToken());
        assertNotNull(refreshed.sessionPolicy());
        assertEquals(
                "RESTORE_LOCAL_SESSION_ALLOWED_UNTIL_REFRESH_TOKEN_EXPIRATION",
                refreshed.sessionPolicy().sessionRestorePolicy()
        );

        tokenAtualizacaoRepository.findByTokenAndRevogadoFalse(registered.refreshToken())
                .ifPresent(token -> {
                    throw new AssertionError("Refresh token anterior deveria estar revogado");
                });

        TokenAtualizacao activeToken = tokenAtualizacaoRepository.findByTokenAndRevogadoFalse(refreshed.refreshToken())
                .orElseThrow(() -> new AssertionError("Novo refresh token nao persistido"));
        assertNotNull(activeToken.getExpiraEm());
    }
}
