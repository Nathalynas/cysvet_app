package com.cysvet.backend.logging;

import com.cysvet.backend.security.AuthenticatedUserPrincipal;
import com.cysvet.backend.tenant.TenantConstants;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Slf4j
@Component
public class RequestObservabilityFilter extends OncePerRequestFilter {

    private static final String REQUEST_ID_HEADER = "X-Request-Id";

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        long startedAt = System.currentTimeMillis();
        String requestId = resolveRequestId(request);
        response.setHeader(REQUEST_ID_HEADER, requestId);

        MDC.put("requestId", requestId);
        MDC.put("httpMethod", request.getMethod());
        MDC.put("httpPath", request.getRequestURI());
        putIfPresent("tenantId", request.getHeader(TenantConstants.HEADER_NAME));
        populateUserId();

        try {
            filterChain.doFilter(request, response);
        } finally {
            populateUserId();
            Object resolvedTenant = request.getAttribute(TenantConstants.REQUEST_ATTRIBUTE);
            if (resolvedTenant != null) {
                MDC.put("tenantId", resolvedTenant.toString());
            }
            MDC.put("httpStatus", Integer.toString(response.getStatus()));
            MDC.put("durationMs", Long.toString(System.currentTimeMillis() - startedAt));

            int status = response.getStatus();
            if (status >= 500) {
                log.error("http_request_completed");
            } else if (status >= 400) {
                log.warn("http_request_completed");
            } else {
                log.info("http_request_completed");
            }

            MDC.clear();
        }
    }

    private String resolveRequestId(HttpServletRequest request) {
        String header = request.getHeader(REQUEST_ID_HEADER);
        if (header == null || header.isBlank()) {
            return UUID.randomUUID().toString();
        }
        return header.trim();
    }

    private void populateUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            MDC.remove("userId");
            return;
        }

        Object principal = authentication.getPrincipal();
        if (principal instanceof AuthenticatedUserPrincipal authenticatedUserPrincipal) {
            MDC.put("userId", Long.toString(authenticatedUserPrincipal.getUserId()));
            return;
        }

        MDC.remove("userId");
    }

    private void putIfPresent(String key, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        MDC.put(key, value.trim());
    }
}
