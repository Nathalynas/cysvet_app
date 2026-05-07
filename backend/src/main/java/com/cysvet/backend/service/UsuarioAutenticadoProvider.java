package com.cysvet.backend.service;

import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.security.AuthenticatedUserPrincipal;
import com.cysvet.backend.tenant.BypassTenant;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
@BypassTenant
@RequiredArgsConstructor
public class UsuarioAutenticadoProvider {

    private final UsuarioRepository userRepository;

    public Usuario getCurrentUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof AuthenticatedUserPrincipal authenticatedUserPrincipal) {
            return userRepository.findById(authenticatedUserPrincipal.getUserId())
                    .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado nao encontrado"));
        }

        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado nao encontrado"));
    }
}
