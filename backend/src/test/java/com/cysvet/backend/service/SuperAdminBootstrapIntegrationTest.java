package com.cysvet.backend.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioRepository;
import com.cysvet.backend.support.TestAccounts;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(properties = {
        // Banco proprio: o super usuario unico de outros contextos de teste impediria a criacao na subida.
        "spring.datasource.url=jdbc:h2:mem:cysvet-bootstrap-test;MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE",
        "app.superadmin.email=root@cysvet.test",
        "app.superadmin.password=segredo123"
})
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Transactional
class SuperAdminBootstrapIntegrationTest {

    private static final String EMAIL = "root@cysvet.test";

    @Autowired
    private SuperAdminBootstrap bootstrap;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private TestAccounts testAccounts;

    // A conta criada na subida do contexto fica commitada no H2 compartilhado entre os contextos de teste.
    @AfterAll
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.NOT_SUPPORTED)
    void removeStartupAccount() {
        usuarioRepository.findByEmail(EMAIL).ifPresent(usuarioRepository::delete);
    }

    @Test
    void createsSuperAdminOnStartup() {
        Usuario user = usuarioRepository.findByEmail(EMAIL).orElseThrow();

        assertThat(user.getPerfil()).isEqualTo(Perfil.SUPER_ADMIN);
        assertThat(user.isTrocarSenha()).isFalse();
        assertThat(passwordEncoder.matches("segredo123", user.getSenha())).isTrue();
    }

    @Test
    void doesNotOverwriteExistingPassword() throws Exception {
        Usuario user = usuarioRepository.findByEmail(EMAIL).orElseThrow();
        String changedHash = passwordEncoder.encode("outra-senha");
        user.setSenha(changedHash);
        usuarioRepository.saveAndFlush(user);

        bootstrap.run(null);

        assertThat(usuarioRepository.findByEmail(EMAIL).orElseThrow().getSenha()).isEqualTo(changedHash);
    }

    @Test
    void doesNotPromoteExistingAdmin() throws Exception {
        usuarioRepository.findByEmail(EMAIL).ifPresent(usuarioRepository::delete);
        usuarioRepository.flush();
        testAccounts.createAdmin("Admin", EMAIL, "senha-admin");

        bootstrap.run(null);

        assertThat(usuarioRepository.findByEmail(EMAIL).orElseThrow().getPerfil()).isEqualTo(Perfil.ADMIN);
    }
}
