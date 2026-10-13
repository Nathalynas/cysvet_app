package com.cysvet.backend.service;

import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
public class SuperAdminBootstrap implements ApplicationRunner {

    private static final String DEFAULT_NAME = "Super usuario";

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final String email;
    private final String password;
    private final String name;

    public SuperAdminBootstrap(
            UsuarioRepository usuarioRepository,
            PasswordEncoder passwordEncoder,
            @Value("${app.superadmin.email:}") String email,
            @Value("${app.superadmin.password:}") String password,
            @Value("${app.superadmin.name:}") String name
    ) {
        this.usuarioRepository = usuarioRepository;
        this.passwordEncoder = passwordEncoder;
        this.email = email;
        this.password = password;
        this.name = name;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (email == null || email.isBlank() || password == null || password.isBlank()) {
            return;
        }
        String normalizedEmail = email.trim();

        Usuario existing = usuarioRepository.findByEmail(normalizedEmail).orElse(null);
        if (existing == null) {
            Usuario otherSuperAdmin = usuarioRepository.findFirstByPerfilOrderByIdAsc(Perfil.SUPER_ADMIN).orElse(null);
            if (otherSuperAdmin != null) {
                log.warn("Ja existe um super usuario ({}); SUPERADMIN_EMAIL {} ignorado",
                        otherSuperAdmin.getEmail(), normalizedEmail);
                return;
            }
            Usuario user = new Usuario();
            user.setNome(name == null || name.isBlank() ? DEFAULT_NAME : name.trim());
            user.setEmail(normalizedEmail);
            user.setSenha(passwordEncoder.encode(password));
            user.setPerfil(Perfil.SUPER_ADMIN);
            user.setTrocarSenha(false);
            usuarioRepository.save(user);
            log.info("Conta de super usuario criada para {}", normalizedEmail);
        } else if (existing.getPerfil() != Perfil.SUPER_ADMIN) {
            log.warn("O e-mail {} ja pertence a um usuario com perfil {}; a conta nao foi promovida a super usuario",
                    normalizedEmail, existing.getPerfil());
        }
    }
}
