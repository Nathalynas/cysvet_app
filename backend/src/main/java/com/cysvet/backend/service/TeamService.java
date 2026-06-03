package com.cysvet.backend.service;

import com.cysvet.backend.dto.user.CreateUserRequest;
import com.cysvet.backend.dto.user.UpdateUserMembershipStatusRequest;
import com.cysvet.backend.dto.user.UpdateUserRequest;
import com.cysvet.backend.dto.user.UserMembershipStatus;
import com.cysvet.backend.dto.user.UserResponse;
import com.cysvet.backend.entity.Empresa;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.entity.UsuarioEmpresa;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.TokenAtualizacaoRepository;
import com.cysvet.backend.repository.UsuarioEmpresaRepository;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.tenant.TenantContext;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final UsuarioRepository usuarioRepository;
    private final UsuarioEmpresaRepository usuarioEmpresaRepository;
    private final TokenAtualizacaoRepository tokenAtualizacaoRepository;
    private final UsuarioAutenticadoProvider usuarioAutenticadoProvider;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<UserResponse> listActiveCompanyMembers() {
        usuarioAutenticadoProvider.getCurrentUser();
        Long tenantId = requireTenantId();

        return usuarioEmpresaRepository.findAllByEmpresaIdOrderByUsuarioNomeAsc(tenantId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public UserResponse createVeterinarian(CreateUserRequest request) {
        requireCurrentAdmin();
        Long tenantId = requireTenantId();

        String normalizedName = request.name().trim();
        String normalizedEmail = request.email().trim();

        Usuario usuario = usuarioRepository.findByEmail(normalizedEmail)
                .map(existingUser -> reuseOrRejectExistingUser(existingUser, tenantId, normalizedName, request.password()))
                .orElseGet(() -> createNewVeterinarian(normalizedName, normalizedEmail, request.password()));

        UsuarioEmpresa membership = new UsuarioEmpresa();
        membership.setUsuario(usuario);
        membership.setEmpresa(requireActiveCompany(tenantId));
        membership.setAtivo(true);

        return toResponse(usuarioEmpresaRepository.saveAndFlush(membership));
    }

    @Transactional
    public UserResponse updateMember(Long userId, UpdateUserRequest request) {
        Usuario currentUser = requireCurrentAdmin();
        Long tenantId = requireTenantId();
        UsuarioEmpresa membership = findMembershipOrThrow(userId, tenantId);
        Usuario targetUser = membership.getUsuario();

        validateMemberCanBeManaged(currentUser, targetUser);

        String normalizedName = request.name().trim();
        String normalizedEmail = request.email().trim();

        usuarioRepository.findByEmail(normalizedEmail)
                .filter(existingUser -> !existingUser.getId().equals(targetUser.getId()))
                .ifPresent(existingUser -> {
                    throw new IllegalArgumentException("E-mail ja cadastrado");
                });

        targetUser.setNome(normalizedName);
        targetUser.setEmail(normalizedEmail);
        usuarioRepository.saveAndFlush(targetUser);

        return toResponse(membership);
    }

    @Transactional
    public UserResponse updateMembershipStatus(Long userId, UpdateUserMembershipStatusRequest request) {
        Usuario currentUser = requireCurrentAdmin();
        Long tenantId = requireTenantId();
        UsuarioEmpresa membership = findMembershipOrThrow(userId, tenantId);

        validateMembershipMutation(currentUser, membership);

        membership.setAtivo(request.status().isActive());
        UsuarioEmpresa savedMembership = usuarioEmpresaRepository.saveAndFlush(membership);

        if (!request.status().isActive()) {
            revokeRefreshTokensWhenWithoutActiveMembership(savedMembership.getUsuario().getId());
        }

        return toResponse(savedMembership);
    }

    @Transactional
    public void removeMember(Long userId) {
        Usuario currentUser = requireCurrentAdmin();
        Long tenantId = requireTenantId();
        UsuarioEmpresa membership = findMembershipOrThrow(userId, tenantId);

        validateMembershipMutation(currentUser, membership);

        Long targetUserId = membership.getUsuario().getId();
        usuarioEmpresaRepository.delete(membership);
        usuarioEmpresaRepository.flush();
        revokeRefreshTokensWhenWithoutActiveMembership(targetUserId);
    }

    private Usuario createNewVeterinarian(String name, String email, String password) {
        Usuario usuario = new Usuario();
        usuario.setNome(name);
        usuario.setEmail(email);
        usuario.setSenha(passwordEncoder.encode(password));
        usuario.setPerfil(Perfil.VETERINARIO);
        return usuarioRepository.saveAndFlush(usuario);
    }

    private Usuario reuseOrRejectExistingUser(Usuario existingUser, Long tenantId, String name, String password) {
        if (existingUser.getPerfil() != Perfil.VETERINARIO) {
            throw new IllegalArgumentException("Apenas usuarios com perfil VETERINARIO podem ser vinculados por este endpoint");
        }

        usuarioEmpresaRepository.findByUsuarioIdAndEmpresaId(existingUser.getId(), tenantId)
                .ifPresent(membership -> {
                    if (membership.isAtivo()) {
                        throw new IllegalArgumentException("Usuario ja vinculado a empresa ativa");
                    }
                    throw new IllegalArgumentException("Usuario ja vinculado a empresa ativa e inativo. Use o endpoint de ativacao");
                });

        if (usuarioEmpresaRepository.countByUsuarioId(existingUser.getId()) > 0) {
            throw new IllegalArgumentException("E-mail ja cadastrado");
        }

        existingUser.setNome(name);
        existingUser.setSenha(passwordEncoder.encode(password));
        existingUser.setPerfil(Perfil.VETERINARIO);
        return usuarioRepository.saveAndFlush(existingUser);
    }

    private Usuario requireCurrentAdmin() {
        Usuario currentUser = usuarioAutenticadoProvider.getCurrentUser();
        if (currentUser.getPerfil() != Perfil.ADMIN) {
            throw new AccessDeniedException("Apenas administradores podem gerenciar a equipe");
        }
        return currentUser;
    }

    private Long requireTenantId() {
        Long tenantId = TenantContext.getTenantId();
        if (tenantId == null) {
            throw new IllegalStateException("Tenant ativo nao encontrado na requisicao");
        }
        return tenantId;
    }

    private Empresa requireActiveCompany(Long tenantId) {
        return usuarioEmpresaRepository.findByUsuarioIdAndEmpresaId(
                        usuarioAutenticadoProvider.getCurrentUser().getId(),
                        tenantId
                )
                .map(UsuarioEmpresa::getEmpresa)
                .orElseThrow(() -> new ResourceNotFoundException("Empresa ativa nao encontrada"));
    }

    private UsuarioEmpresa findMembershipOrThrow(Long userId, Long tenantId) {
        return usuarioEmpresaRepository.findByUsuarioIdAndEmpresaId(userId, tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("Vinculo do usuario com a empresa ativa nao encontrado"));
    }

    private void validateMembershipMutation(Usuario currentUser, UsuarioEmpresa membership) {
        validateMemberCanBeManaged(currentUser, membership.getUsuario());
    }

    private void validateMemberCanBeManaged(Usuario currentUser, Usuario targetUser) {
        if (targetUser.getPerfil() == Perfil.ADMIN) {
            throw new IllegalArgumentException("Administradores nao podem ser alterados por este endpoint");
        }
        if (currentUser.getId().equals(targetUser.getId())) {
            throw new IllegalArgumentException("Nao e permitido alterar o proprio usuario");
        }
    }

    private void revokeRefreshTokensWhenWithoutActiveMembership(Long userId) {
        if (!usuarioEmpresaRepository.existsByUsuarioIdAndAtivoTrue(userId)) {
            tokenAtualizacaoRepository.deleteAllByUsuarioId(userId);
        }
    }

    private UserResponse toResponse(UsuarioEmpresa membership) {
        Usuario usuario = membership.getUsuario();
        return new UserResponse(
                usuario.getId(),
                usuario.getNome(),
                usuario.getEmail(),
                usuario.getPerfil(),
                membership.getEmpresa().getId(),
                membership.getEmpresa().getNome(),
                UserMembershipStatus.from(membership.isAtivo())
        );
    }
}
