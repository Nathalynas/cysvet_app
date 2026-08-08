package com.cysvet.backend.config;

import jakarta.validation.constraints.NotEmpty;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private final Docs docs = new Docs();
    private final Errors errors = new Errors();
    private final Cors cors = new Cors();

    @Getter
    @Setter
    public static class Docs {
        private boolean enabled = true;
    }

    @Getter
    @Setter
    public static class Errors {
        private boolean includeDetails = true;
    }

    @Getter
    @Setter
    public static class Cors {
        @NotEmpty
        private List<String> allowedOrigins = new ArrayList<>();
        @NotEmpty
        private List<String> allowedMethods = new ArrayList<>();
        @NotEmpty
        private List<String> allowedHeaders = new ArrayList<>();
        private boolean allowCredentials = true;
    }
}
