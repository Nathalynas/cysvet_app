package com.cysvet.backend.security;

import com.cysvet.backend.service.TenantAccessService;
import com.cysvet.backend.tenant.TenantConstants;
import com.cysvet.backend.tenant.TenantContext;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    static final String INVALID_SESSION_MESSAGE = "Sessao expirada ou token invalido";

    private final JwtService jwtService;
    private final CustomUserDetailService userDetailsService;
    private final TenantAccessService tenantAccessService;
    private final JsonErrorResponder errorResponder;

    // Login, registro, refresh e logout sao publicos. O cliente pode reenviar o
    // access token expirado junto; valida-lo aqui bloquearia justamente o refresh.
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return path(request).startsWith("/api/auth/");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                filterChain.doFilter(request, response);
                return;
            }

            String token = authHeader.substring(7);
            String username = jwtService.extractUsername(token);
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                if (jwtService.isTokenValid(token, userDetails.getUsername())) {
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }

            AuthenticatedUserPrincipal principal = authenticatedPrincipal();
            if (principal == null) {
                rejectInvalidSession(response);
                return;
            }

            if (requiresTenantValidation(request)) {
                Long tenantId = extractTenantId(request, response);
                if (tenantId == null) {
                    return;
                }

                if (!tenantAccessService.userHasAccessToTenant(principal.getUserId(), tenantId)) {
                    errorResponder.write(response, HttpServletResponse.SC_FORBIDDEN, "Usuario sem acesso a empresa informada");
                    return;
                }

                TenantContext.setTenantId(tenantId);
                request.setAttribute(TenantConstants.REQUEST_ATTRIBUTE, tenantId);
            }

            filterChain.doFilter(request, response);
        } catch (JwtException | IllegalArgumentException | UsernameNotFoundException exception) {
            rejectInvalidSession(response);
        } finally {
            TenantContext.clear();
        }
    }

    private void rejectInvalidSession(HttpServletResponse response) throws IOException {
        SecurityContextHolder.clearContext();
        errorResponder.write(response, HttpServletResponse.SC_UNAUTHORIZED, INVALID_SESSION_MESSAGE);
    }

    private boolean requiresTenantValidation(HttpServletRequest request) {
        String path = path(request);
        return !path.startsWith("/swagger-ui")
                && !path.startsWith("/v3/api-docs")
                && !path.startsWith("/h2-console")
                && !path.startsWith("/actuator");
    }

    // URI sem o context path: igual no Tomcat e no MockMvc (que nao preenche o servletPath).
    private static String path(HttpServletRequest request) {
        return request.getRequestURI().substring(request.getContextPath().length());
    }

    private AuthenticatedUserPrincipal authenticatedPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof AuthenticatedUserPrincipal principal) {
            return principal;
        }
        return null;
    }

    private Long extractTenantId(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String tenantId = request.getHeader(TenantConstants.HEADER_NAME);
        if (tenantId == null || tenantId.isBlank()) {
            errorResponder.write(response, HttpServletResponse.SC_BAD_REQUEST, "Header empresaid e obrigatorio");
            return null;
        }
        try {
            return Long.valueOf(tenantId.trim());
        } catch (NumberFormatException exception) {
            errorResponder.write(response, HttpServletResponse.SC_BAD_REQUEST, "Header empresaid deve ser numerico");
            return null;
        }
    }
}
