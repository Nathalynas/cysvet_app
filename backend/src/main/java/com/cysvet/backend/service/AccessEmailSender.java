package com.cysvet.backend.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class AccessEmailSender {

    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final String from;

    public AccessEmailSender(
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.mail.from:}") String from
    ) {
        this.mailSenderProvider = mailSenderProvider;
        this.from = from;
    }

    public boolean sendTemporaryPassword(String toEmail, String userName, String companyName, String temporaryPassword) {
        // O JavaMailSender so existe quando spring.mail.host esta configurado; em dev o envio e ignorado.
        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null) {
            log.warn("SMTP nao configurado; e-mail de acesso para {} nao enviado", toEmail);
            return true;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        if (from != null && !from.isBlank()) {
            message.setFrom(from);
        }
        message.setSubject("Seu acesso ao CYSVET");
        message.setText("""
                Olá, %s!

                A empresa %s foi cadastrada no CYSVET.

                Login: %s
                Senha provisória: %s

                No primeiro acesso você deverá definir uma nova senha.
                """.formatted(userName, companyName, toEmail, temporaryPassword));

        try {
            mailSender.send(message);
            return true;
        } catch (MailException e) {
            log.error("Falha ao enviar e-mail de acesso para {}: {}", toEmail, e.getMessage());
            return false;
        }
    }
}
