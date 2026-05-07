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
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final CustomUserDetailService userDetailsService;
    private final TenantAccessService tenantAccessService;

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

            if (requiresTenantValidation(request)) {
                AuthenticatedUserPrincipal principal = extractPrincipal();
                Long tenantId = extractTenantId(request, response);
                if (tenantId == null) {
                    return;
                }

                if (!tenantAccessService.userHasAccessToTenant(principal.getUserId(), tenantId)) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Usuario sem acesso a empresa informada");
                    return;
                }

                TenantContext.setTenantId(tenantId);
                request.setAttribute(TenantConstants.REQUEST_ATTRIBUTE, tenantId);
            }

            filterChain.doFilter(request, response);
        } catch (JwtException | IllegalArgumentException exception) {
            SecurityContextHolder.clearContext();
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token JWT invalido");
        } finally {
            TenantContext.clear();
        }
    }

    private boolean requiresTenantValidation(HttpServletRequest request) {
        String path = request.getServletPath();
        return !path.startsWith("/api/auth/")
                && !path.startsWith("/swagger-ui")
                && !path.startsWith("/v3/api-docs")
                && !path.startsWith("/h2-console")
                && !path.startsWith("/actuator");
    }

    private AuthenticatedUserPrincipal extractPrincipal() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof AuthenticatedUserPrincipal authenticatedUserPrincipal) {
            return authenticatedUserPrincipal;
        }

        throw new IllegalStateException("Principal autenticado invalido");
    }

    private Long extractTenantId(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String tenantId = request.getHeader(TenantConstants.HEADER_NAME);
        if (tenantId == null || tenantId.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Header empresaid e obrigatorio");
            return null;
        }
        try {
            return Long.valueOf(tenantId.trim());
        } catch (NumberFormatException exception) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Header empresaid deve ser numerico");
            return null;
        }
    }
}
