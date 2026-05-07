package com.cysvet.backend.tenant;

public final class TenantContext {

    private static final ThreadLocal<Long> CURRENT_TENANT = new ThreadLocal<>();
    private static final ThreadLocal<Boolean> BYPASS_ENABLED = ThreadLocal.withInitial(() -> false);

    private TenantContext() {
    }

    public static void setTenantId(Long tenantId) {
        CURRENT_TENANT.set(tenantId);
    }

    public static Long getTenantId() {
        return CURRENT_TENANT.get();
    }

    public static boolean hasTenant() {
        return CURRENT_TENANT.get() != null;
    }

    public static void enableBypass() {
        BYPASS_ENABLED.set(true);
    }

    public static void disableBypass() {
        BYPASS_ENABLED.set(false);
    }

    public static boolean isBypassEnabled() {
        return Boolean.TRUE.equals(BYPASS_ENABLED.get());
    }

    public static void clear() {
        CURRENT_TENANT.remove();
        BYPASS_ENABLED.remove();
    }
}
