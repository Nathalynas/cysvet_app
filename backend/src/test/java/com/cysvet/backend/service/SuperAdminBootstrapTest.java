package com.cysvet.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.cysvet.backend.entity.Perfil;
import com.cysvet.backend.entity.Usuario;
import com.cysvet.backend.repository.UsuarioRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;

class SuperAdminBootstrapTest {

    private final UsuarioRepository repository = mock(UsuarioRepository.class);
    private final PasswordEncoder encoder = mock(PasswordEncoder.class);

    private SuperAdminBootstrap bootstrap(String name) {
        return new SuperAdminBootstrap(repository, encoder, "novo@cysvet.test", "segredo123", name);
    }

    @Test
    void doesNotCreateSecondSuperAdmin() throws Exception {
        Usuario existing = new Usuario();
        existing.setEmail("root@cysvet.test");
        existing.setPerfil(Perfil.SUPER_ADMIN);
        when(repository.findByEmail("novo@cysvet.test")).thenReturn(Optional.empty());
        when(repository.findFirstByPerfilOrderByIdAsc(Perfil.SUPER_ADMIN)).thenReturn(Optional.of(existing));

        Logger logger = (Logger) LoggerFactory.getLogger(SuperAdminBootstrap.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        try {
            bootstrap("Root").run(null);
        } finally {
            logger.detachAppender(appender);
        }

        verify(repository, never()).save(any(Usuario.class));
        assertThat(appender.list).extracting(ILoggingEvent::getFormattedMessage)
                .containsExactly("Ja existe um super usuario (root@cysvet.test); "
                        + "SUPERADMIN_EMAIL novo@cysvet.test ignorado");
    }

    @Test
    void blankNameFallsBackToDefault() throws Exception {
        when(repository.findByEmail("novo@cysvet.test")).thenReturn(Optional.empty());
        when(repository.findFirstByPerfilOrderByIdAsc(Perfil.SUPER_ADMIN)).thenReturn(Optional.empty());
        when(encoder.encode("segredo123")).thenReturn("hash");

        bootstrap("").run(null);

        ArgumentCaptor<Usuario> captor = ArgumentCaptor.forClass(Usuario.class);
        verify(repository).save(captor.capture());
        assertThat(captor.getValue().getNome()).isEqualTo("Super usuario");
        assertThat(captor.getValue().getPerfil()).isEqualTo(Perfil.SUPER_ADMIN);
    }
}
