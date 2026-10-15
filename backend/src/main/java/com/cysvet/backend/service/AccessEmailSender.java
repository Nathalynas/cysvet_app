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
        return send(toEmail, userName, companyName, temporaryPassword,
                "A empresa %s foi cadastrada no CYSVET.".formatted(companyName));
    }

    public boolean sendNewTemporaryPassword(String toEmail, String userName, String companyName, String temporaryPassword) {
        return send(toEmail, userName, companyName, temporaryPassword,
                "Uma nova senha provisória foi gerada para o seu acesso à empresa %s no CYSVET."
                        .formatted(companyName));
    }

    public boolean sendTeamInvite(String toEmail, String userName, String companyName, String temporaryPassword) {
        return send(toEmail, userName, companyName, temporaryPassword,
                "Você foi adicionado à equipe da empresa %s no CYSVET.".formatted(companyName));
    }

    private boolean send(String toEmail, String userName, String companyName, String temporaryPassword, String intro) {
        // O JavaMailSender so existe quando spring.mail.host esta configurado; sem ele o envio nao ocorre
        // e o chamador e avisado para que o super usuario use "Reenviar senha" depois.
        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null) {
            log.warn("SMTP nao configurado; e-mail de acesso para {} nao enviado", toEmail);
            return false;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(toEmail);
        if (from != null && !from.isBlank()) {
            message.setFrom(from);
        }
        message.setSubject("Seu acesso ao CYSVET");
        message.setText("""
                Olá, %s!

                %s

                Login: %s
                Senha provisória: %s

                No primeiro acesso você deverá definir uma nova senha.
                """.formatted(userName, intro, toEmail, temporaryPassword));

        try {
            mailSender.send(message);
            return true;
        } catch (MailException e) {
            log.error("Falha ao enviar e-mail de acesso para {}: {}", toEmail, e.getMessage());
            return false;
        }
    }
}
