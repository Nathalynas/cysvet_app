package com.cysvet.backend.tenant;

import lombok.RequiredArgsConstructor;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Aspect
@Component
@Order(0)
@RequiredArgsConstructor
public class TenantBypassAspect {

    private final TenantExecution tenantExecution;

    @Around("@within(com.cysvet.backend.tenant.BypassTenant) || @annotation(com.cysvet.backend.tenant.BypassTenant)")
    public Object executeWithoutTenant(ProceedingJoinPoint joinPoint) {
        return tenantExecution.runWithoutTenant(() -> {
            try {
                return joinPoint.proceed();
            } catch (RuntimeException runtimeException) {
                throw runtimeException;
            } catch (Throwable throwable) {
                throw new IllegalStateException("Falha ao executar operacao sem escopo de tenant", throwable);
            }
        });
    }
}
