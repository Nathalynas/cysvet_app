package com.cysvet.backend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.dto.auth.RegisterRequest;
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
    }
}
