package com.cysvet.backend.service;

import com.cysvet.backend.dto.auth.AuthResponse;
import com.cysvet.backend.dto.auth.EmpresaPermitidaResponse;
import com.cysvet.backend.dto.auth.UsuarioAutenticadoResponse;
import com.cysvet.backend.dto.auth.SessionPolicyResponse;
import com.cysvet.backend.dto.auth.LoginRequest;
import com.cysvet.backend.dto.auth.LogoutRequest;
import com.cysvet.backend.dto.auth.TokenRefreshRequest;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.TokenAtualizacao;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.repository.TokenAtualizacaoRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.security.JwtService;
import com.cysvet.backend.tenant.BypassTenant;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@BypassTenant
@RequiredArgsConstructor
public class AuthService {

    @PersistenceContext
    private EntityManager entityManager;

    private final UsuarioRepository userRepository;
    private final TokenAtualizacaoRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final TenantAccessService tenantAccessService;

    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

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

    @Transactional
    public void changeRequiredPassword(Long userId, String newPassword) {
        Usuario user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Usuario nao encontrado"));
        if (!user.isTrocarSenha()) {
            throw new IllegalArgumentException("Troca de senha nao solicitada");
        }
        user.setSenha(passwordEncoder.encode(newPassword));
        user.setTrocarSenha(false);
        userRepository.save(user);
    }

    private AuthResponse buildAuthResponse(Long userId) {
        if (userId == null) {
            throw new IllegalStateException("Usuario persistido sem identificador");
        }

        entityManager.flush();
        entityManager.clear();

        Usuario managedUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Usuario nao encontrado para emissao do token"));

        boolean superAdmin = managedUser.getPerfil() == Perfil.SUPER_ADMIN;
        List<UsuarioEmpresa> memberships = superAdmin
                ? List.of()
                : tenantAccessService.findActiveMemberships(managedUser.getId());
        if (!superAdmin && memberships.isEmpty()) {
            if (tenantAccessService.hasOnlyInactiveCompanies(managedUser.getId())) {
                throw new AccessDeniedException("Empresa desativada");
            }
            throw new AccessDeniedException("Usuario sem empresa vinculada ativa");
        }

        Instant issuedAt = Instant.now();
        String accessToken = jwtService.generateToken(
                managedUser,
                List.of(new SimpleGrantedAuthority("ROLE_" + managedUser.getPerfil().name())),
                issuedAt
        );
        String refreshTokenValue = UUID.randomUUID().toString();
        Instant refreshExpiresAt = issuedAt.plusMillis(refreshExpirationMs);

        TokenAtualizacao refreshToken = new TokenAtualizacao();
        refreshToken.setToken(refreshTokenValue);
        refreshToken.setUsuario(managedUser);
        refreshToken.setExpiraEm(refreshExpiresAt);
        refreshToken.setRevogado(false);
        refreshTokenRepository.saveAndFlush(refreshToken);

        List<EmpresaPermitidaResponse> empresas = memberships.stream()
                .map(UsuarioEmpresa::getEmpresa)
                .map(this::toCompanyResponse)
                .toList();
        Long empresaAtivaId = memberships.isEmpty() ? null : memberships.get(0).getEmpresa().getId();

        return new AuthResponse(
                accessToken,
                refreshTokenValue,
                new UsuarioAutenticadoResponse(
                        managedUser.getId(),
                        managedUser.getNome(),
                        managedUser.getEmail(),
                        managedUser.getPerfil(),
                        managedUser.isTrocarSenha()
                ),
                empresaAtivaId,
                empresas,
                new SessionPolicyResponse(
                        jwtService.resolveAccessTokenExpiration(issuedAt),
                        refreshExpiresAt,
                        "RESTORE_LOCAL_SESSION_ALLOWED_UNTIL_REFRESH_TOKEN_EXPIRATION",
                        "WHEN_ACCESS_TOKEN_EXPIRES_USE_REFRESH_TOKEN_ON_NEXT_ONLINE_REVALIDATION"
                )
        );
    }

    private EmpresaPermitidaResponse toCompanyResponse(Empresa empresa) {
        return new EmpresaPermitidaResponse(
                empresa.getId(),
                empresa.getNome(),
                empresa.getEmail()
        );
    }
}
