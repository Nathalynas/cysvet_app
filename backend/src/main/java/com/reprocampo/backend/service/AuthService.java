package com.reprocampo.backend.service;

import com.reprocampo.backend.dto.auth.AuthResponse;
import com.reprocampo.backend.dto.auth.UsuarioAutenticadoResponse;
import com.reprocampo.backend.dto.auth.LoginRequest;
import com.reprocampo.backend.dto.auth.LogoutRequest;
import com.reprocampo.backend.dto.auth.RegisterRequest;
import com.reprocampo.backend.dto.auth.TokenRefreshRequest;
import com.reprocampo.backend.entity.TokenAtualizacao;
import com.reprocampo.backend.entity.Perfil;
import com.reprocampo.backend.entity.Usuario;
import com.reprocampo.backend.repository.TokenAtualizacaoRepository;
import com.reprocampo.backend.repository.UsuarioRepository;
import com.reprocampo.backend.security.JwtService;
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
        userRepository.saveAndFlush(user);
        Usuario savedUser = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalStateException("Usuario nao foi persistido corretamente"));

        return buildAuthResponse(savedUser);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        Usuario user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalArgumentException("Usuario nao encontrado"));
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse refresh(TokenRefreshRequest request) {
        TokenAtualizacao refreshToken = refreshTokenRepository.findByTokenAndRevogadoFalse(request.refreshToken())
                .filter(token -> token.getExpiraEm().isAfter(Instant.now()))
                .orElseThrow(() -> new IllegalArgumentException("Refresh token invalido"));

        refreshToken.setRevogado(true);
        refreshTokenRepository.save(refreshToken);

        return buildAuthResponse(refreshToken.getUsuario());
    }

    @Transactional
    public void logout(LogoutRequest request) {
        TokenAtualizacao refreshToken = refreshTokenRepository.findByTokenAndRevogadoFalse(request.refreshToken())
                .orElseThrow(() -> new IllegalArgumentException("Refresh token invalido"));
        refreshToken.setRevogado(true);
        refreshTokenRepository.save(refreshToken);
    }

    private AuthResponse buildAuthResponse(Usuario user) {
        Usuario managedUser = resolvePersistedUser(user);

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

    private Usuario resolvePersistedUser(Usuario user) {
        if (user.getId() != null) {
            return entityManager.getReference(Usuario.class, user.getId());
        }

        if (user.getEmail() != null && !user.getEmail().isBlank()) {
            return userRepository.findByEmail(user.getEmail())
                    .orElseThrow(() -> new IllegalStateException("Usuario nao encontrado para emissao do token"));
        }

        throw new IllegalStateException("Usuario sem identificador persistido");
    }
}
