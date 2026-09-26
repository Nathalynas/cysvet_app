package com.cysvet.backend.config;

import com.cysvet.backend.repository.TenantFilteredJpaRepository;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.cysvet.backend.repository",
        repositoryBaseClass = TenantFilteredJpaRepository.class
)
public class JpaRepositoryConfig {
}
