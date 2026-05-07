package com.cysvet.backend.config;

import com.cysvet.backend.tenant.TenantIdentifierResolver;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.hibernate.cfg.AvailableSettings;
import org.springframework.boot.autoconfigure.orm.jpa.HibernatePropertiesCustomizer;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class HibernateTenantConfig implements HibernatePropertiesCustomizer {

    private final TenantIdentifierResolver tenantIdentifierResolver;

    @Override
    public void customize(Map<String, Object> hibernateProperties) {
        hibernateProperties.put(AvailableSettings.MULTI_TENANT_IDENTIFIER_RESOLVER, tenantIdentifierResolver);
    }
}
