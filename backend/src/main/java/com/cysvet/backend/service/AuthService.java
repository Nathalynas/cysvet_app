package com.cysvet.backend.service;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.dto.auth.UsuarioAutenticadoResponse;
import com.cysvet.backend.dto.auth.LoginRequest;
import com.cysvet.backend.dto.auth.LogoutRequest;
import com.cysvet.backend.dto.auth.RegisterRequest;
import com.cysvet.backend.dto.auth.TokenRefreshRequest;
import com.cysvet.backend.entity.TokenAtualizacao;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.TokenAtualizacaoRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.security.JwtService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Instant;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    @PersistenceContext
    private EntityManager entityManager;

    private final UsuarioRepository userRepository;
    private final TokenAtualizacaoRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        userRepository.findByEmail(request.email()).ifPresent(existing -> {
            throw new IllegalArgumentException("E-mail ja cadastrado");
        });

        Usuario user = new Usuario();
        user.setNome(request.name());
        user.setEmail(request.email());
        user.setSenha(passwordEncoder.encode(request.password()));
        user.setPerfil(Perfil.USER);
        Usuario savedUser = userRepository.saveAndFlush(user);

        return buildAuthResponse(savedUser.getId());
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        Usuario user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalArgumentException("Usuario nao encontrado"));
        return buildAuthResponse(user.getId());
    }

    @Transactional
    public AuthResponse refresh(TokenRefreshRequest request) {
        TokenAtualizacao refreshToken = refreshTokenRepository.findByTokenAndRevogadoFalse(request.refreshToken())
                .filter(token -> token.getExpiraEm().isAfter(Instant.now()))
                .orElseThrow(() -> new IllegalArgumentException("Refresh token invalido"));

        refreshToken.setRevogado(true);
        refreshTokenRepository.save(refreshToken);

        return buildAuthResponse(refreshToken.getUsuario().getId());
    }

    @Transactional
    public void logout(LogoutRequest request) {
        TokenAtualizacao refreshToken = refreshTokenRepository.findByTokenAndRevogadoFalse(request.refreshToken())
                .orElseThrow(() -> new IllegalArgumentException("Refresh token invalido"));
        refreshToken.setRevogado(true);
        refreshTokenRepository.save(refreshToken);
    }

    private AuthResponse buildAuthResponse(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Usuario persistido sem identificador");
        }

        entityManager.flush();
        entityManager.clear();

        Usuario managedUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Usuario nao encontrado para emissao do token"));

        String accessToken = jwtService.generateToken(managedUser.getEmail());
        String refreshTokenValue = UUID.randomUUID().toString();

        TokenAtualizacao refreshToken = new TokenAtualizacao();
        refreshToken.setToken(refreshTokenValue);
        refreshToken.setUsuario(managedUser);
        refreshToken.setExpiraEm(Instant.now().plusMillis(refreshExpirationMs));
        refreshToken.setRevogado(false);
        refreshTokenRepository.saveAndFlush(refreshToken);

        return new AuthResponse(
                accessToken,
                refreshTokenValue,
                new UsuarioAutenticadoResponse(managedUser.getId(), managedUser.getNome(), managedUser.getEmail())
        );
    }
}
