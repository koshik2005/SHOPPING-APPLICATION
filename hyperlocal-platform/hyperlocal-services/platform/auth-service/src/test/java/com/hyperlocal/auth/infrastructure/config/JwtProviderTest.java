package com.hyperlocal.auth.infrastructure.config;

import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class JwtProviderTest {

    private JwtProvider jwtProvider;
    private final String secret = "HyperLocalDevSecretKeyForJWTSigningMinimum256BitsLong!";
    private final long expirySeconds = 900;

    @BeforeEach
    void setUp() {
        jwtProvider = new JwtProvider(secret, expirySeconds);
    }

    @Test
    void testGenerateAccessTokenAndValidate() {
        UUID userId = UUID.randomUUID();
        String email = "test@hyperlocal.app";
        String role = "CUSTOMER";

        String token = jwtProvider.generateAccessToken(userId, email, role);
        assertNotNull(token);
        assertTrue(jwtProvider.validateToken(token));

        Claims claims = jwtProvider.getClaims(token);
        assertEquals(userId.toString(), claims.getSubject());
        assertEquals(email, claims.get("email"));
        assertEquals(role, claims.get("role"));
    }

    @Test
    void testValidateInvalidToken() {
        assertFalse(jwtProvider.validateToken("invalid.jwt.token.string"));
    }
}
