package com.cysvet.backend.security;

import com.cysvet.backend.entity.Usuario;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.Date;
import java.util.List;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-ms}") long expirationMs
    ) {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    public String generateToken(Usuario user, Collection<? extends GrantedAuthority> authorities) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + expirationMs);
        return Jwts.builder()
                .subject(user.getEmail())
                .claim("uid", user.getId())
                .claim("username", user.getEmail())
                .claim("roles", authorities.stream().map(GrantedAuthority::getAuthority).toList())
                .issuedAt(now)
                .expiration(expiration)
                .signWith(signingKey, SignatureAlgorithm.HS256)
                .compact();
    }

    public String extractUsername(String token) {
        return extractClaims(token).getSubject();
    }

    public boolean isTokenValid(String token, String username) {
        Claims claims = extractClaims(token);
        return username.equals(claims.getSubject()) && claims.getExpiration().after(new Date());
    }

    public Long extractUserId(String token) {
        Object userId = extractClaims(token).get("uid");
        if (userId instanceof Integer integerValue) {
            return integerValue.longValue();
        }
        if (userId instanceof Long longValue) {
            return longValue;
        }
        if (userId instanceof String stringValue) {
            return Long.valueOf(stringValue);
        }
        throw new IllegalArgumentException("Claim uid invalida no token");
    }

    public List<String> extractRoles(String token) {
        Object roles = extractClaims(token).get("roles");
        if (roles instanceof List<?> values) {
            return values.stream().map(String::valueOf).toList();
        }
        return List.of();
    }

    private Claims extractClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
