package com.cysvet.backend.service;

import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.exception.ResourceNotFoundException;
import com.cysvet.backend.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class UsuarioAutenticadoProvider {

    private final UsuarioRepository userRepository;

    public Usuario getCurrentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado nao encontrado"));
    }
}
