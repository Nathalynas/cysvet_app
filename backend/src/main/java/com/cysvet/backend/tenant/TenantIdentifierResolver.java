package com.cysvet.backend.tenant;

import org.hibernate.context.spi.CurrentTenantIdentifierResolver;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class TenantIdentifierResolver implements CurrentTenantIdentifierResolver<Long> {

    @Override
    public Long resolveCurrentTenantIdentifier() {
        if (TenantContext.isBypassEnabled()) {
            return TenantConstants.ROOT_TENANT_ID;
        }

        Long tenantId = TenantContext.getTenantId();
        if (tenantId == null) {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication == null) {
                return TenantConstants.ROOT_TENANT_ID;
            }

            throw new IllegalStateException("Nenhum tenant ativo foi definido para a sessao atual");
        }

        return tenantId;
    }

    @Override
    public boolean validateExistingCurrentSessions() {
        return true;
    }

    @Override
    public boolean isRoot(Long tenantId) {
        return TenantConstants.ROOT_TENANT_ID.equals(tenantId);
    }
}
