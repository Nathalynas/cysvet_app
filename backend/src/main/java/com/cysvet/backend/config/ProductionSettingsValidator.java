package com.cysvet.backend.config;

import java.nio.charset.StandardCharsets;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("prod")
@RequiredArgsConstructor
public class ProductionSettingsValidator implements InitializingBean {

    private final AppProperties appProperties;

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    @Value("${spring.h2.console.enabled:false}")
    private boolean h2ConsoleEnabled;

    @Override
    public void afterPropertiesSet() {
        if (appProperties.getCors().getAllowedOrigins().isEmpty()) {
            throw new IllegalStateException("APP_CORS_ALLOWED_ORIGINS deve ser configurado em producao");
        }

        if (jwtSecret == null || jwtSecret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SECRET deve ter pelo menos 32 bytes em producao");
        }

        if (h2ConsoleEnabled) {
            throw new IllegalStateException("H2 console nao pode estar habilitado em producao");
        }
    }
}
