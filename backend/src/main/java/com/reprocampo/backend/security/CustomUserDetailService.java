package com.reprocampo.backend.security;

import com.reprocampo.backend.entity.Usuario;
import com.reprocampo.backend.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CustomUserDetailService implements UserDetailsService {

    private final UsuarioRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Usuario user = userRepository.findByEmail(username)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario nao encontrado"));

        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getSenha(),
                java.util.List.of(new SimpleGrantedAuthority("ROLE_" + user.getPerfil().name()))
        );
    }
}
