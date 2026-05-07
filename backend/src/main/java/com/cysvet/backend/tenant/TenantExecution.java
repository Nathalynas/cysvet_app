package com.cysvet.backend.tenant;

import java.util.function.Supplier;
import org.springframework.stereotype.Component;

@Component
public class TenantExecution {

    public <T> T runWithoutTenant(Supplier<T> action) {
        boolean previousBypass = TenantContext.isBypassEnabled();
        Long previousTenant = TenantContext.getTenantId();

        TenantContext.enableBypass();
        TenantContext.setTenantId(TenantConstants.ROOT_TENANT_ID);
        try {
            return action.get();
        } finally {
            restore(previousBypass, previousTenant);
        }
    }

    public void runWithoutTenant(Runnable action) {
        runWithoutTenant(() -> {
            action.run();
            return null;
        });
    }

    private void restore(boolean previousBypass, Long previousTenant) {
        if (previousTenant == null) {
            TenantContext.clear();
            return;
        }

        TenantContext.setTenantId(previousTenant);
        if (previousBypass) {
            TenantContext.enableBypass();
        } else {
            TenantContext.disableBypass();
        }
    }
}
