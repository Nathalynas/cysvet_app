package com.cysvet.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

class AccessEmailSenderTest {

    @SuppressWarnings("unchecked")
    private final ObjectProvider<JavaMailSender> provider = mock(ObjectProvider.class);
    private final JavaMailSender mailSender = mock(JavaMailSender.class);

    @Test
    void sendsMessageWithTemporaryPassword() {
        when(provider.getIfAvailable()).thenReturn(mailSender);
        AccessEmailSender sender = new AccessEmailSender(provider, "no-reply@cysvet.test");

        boolean sent = sender.sendTemporaryPassword("ana@fazenda.test", "Ana", "Fazenda Boa", "Abc23456789x");

        assertThat(sent).isTrue();
        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mailSender).send(captor.capture());
        SimpleMailMessage message = captor.getValue();
        assertThat(message.getTo()).containsExactly("ana@fazenda.test");
        assertThat(message.getFrom()).isEqualTo("no-reply@cysvet.test");
        assertThat(message.getSubject()).isEqualTo("Seu acesso ao CYSVET");
        assertThat(message.getText())
                .contains("Olá, Ana!")
                .contains("A empresa Fazenda Boa foi cadastrada no CYSVET.")
                .contains("Login: ana@fazenda.test")
                .contains("Senha provisória: Abc23456789x");
    }

    @Test
    void returnsFalseWhenMailSenderFails() {
        when(provider.getIfAvailable()).thenReturn(mailSender);
        doThrow(new MailSendException("smtp fora do ar")).when(mailSender).send(any(SimpleMailMessage.class));
        AccessEmailSender sender = new AccessEmailSender(provider, "no-reply@cysvet.test");

        assertThat(sender.sendTemporaryPassword("ana@fazenda.test", "Ana", "Fazenda Boa", "Abc23456789x")).isFalse();
    }

    @Test
    void resendUsesNewPasswordWording() {
        when(provider.getIfAvailable()).thenReturn(mailSender);
        AccessEmailSender sender = new AccessEmailSender(provider, "no-reply@cysvet.test");

        boolean sent = sender.sendNewTemporaryPassword("ana@fazenda.test", "Ana", "Fazenda Boa", "Abc23456789x");

        assertThat(sent).isTrue();
        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mailSender).send(captor.capture());
        assertThat(captor.getValue().getText())
                .contains("Olá, Ana!")
                .contains("Uma nova senha provisória foi gerada para o seu acesso à empresa Fazenda Boa no CYSVET.")
                .doesNotContain("foi cadastrada")
                .contains("Login: ana@fazenda.test")
                .contains("Senha provisória: Abc23456789x");
    }

    @Test
    void returnsFalseWithoutSendingWhenSmtpIsNotConfigured() {
        when(provider.getIfAvailable()).thenReturn(null);
        AccessEmailSender sender = new AccessEmailSender(provider, "");

        assertThat(sender.sendTemporaryPassword("ana@fazenda.test", "Ana", "Fazenda Boa", "Abc23456789x")).isFalse();
        assertThat(sender.sendNewTemporaryPassword("ana@fazenda.test", "Ana", "Fazenda Boa", "Abc23456789x")).isFalse();
    }
}
