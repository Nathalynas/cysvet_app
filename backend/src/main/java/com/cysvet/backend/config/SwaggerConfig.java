package com.cysvet.backend.config;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConditionalOnProperty(prefix = "app.docs", name = "enabled", havingValue = "true", matchIfMissing = true)
@SecurityScheme(
        name = "bearerAuth",
        type = SecuritySchemeType.HTTP,
        scheme = "bearer",
        bearerFormat = "JWT",
        description = "Informe o token JWT no header Authorization usando o formato Bearer."
)
public class SwaggerConfig {

    public static final String BEARER_SCHEME = "bearerAuth";

    @Bean
    public OpenAPI cysvetOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Cysvet API")
                        .version("v1")
                        .description("API do backend Cysvet para autenticacao, sincronizacao, propriedades, animais, eventos reprodutivos, visitas e relatorios.")
                        .contact(new Contact().name("Equipe Cysvet")));
    }
}
