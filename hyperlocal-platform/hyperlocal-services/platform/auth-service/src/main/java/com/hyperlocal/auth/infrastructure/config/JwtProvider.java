package com.hyperlocal.auth.infrastructure.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.interfaces.RSAPublicKey;
import java.util.*;

@Component
public class JwtProvider {

    private final String activeKid;
    private final PrivateKey privateKey;
    private final PublicKey publicKey;
    private final long tokenValidityMs;

    public JwtProvider(
            @Value("${jwt.secret:HyperLocalDevSecretKeyForJWTSigningMinimum256BitsLong!}") String secret,
            @Value("${jwt.expiry.access:900}") long expirySeconds) {
        this.tokenValidityMs = expirySeconds * 1000;
        this.activeKid = "key-" + UUID.randomUUID().toString().substring(0, 8);

        // Generate RSA key pair for asymmetric RS256 signing (JWKS ready)
        try {
            KeyPair keyPair = Jwts.SIG.RS256.keyPair().build();
            this.privateKey = keyPair.getPrivate();
            this.publicKey = keyPair.getPublic();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to generate RSA keypair for JWT signing", e);
        }
    }

    /**
     * Legacy helper method matching tests. Generates a token with a single role.
     */
    public String generateAccessToken(UUID userId, String email, String role) {
        return generateAccessToken(userId, email, Set.of(role), null, null, UUID.randomUUID(), "legacy");
    }

    /**
     * Advanced token generator containing RBAC roles, tenant scopes (branchId, shopId),
     * sessionId and deviceId.
     */
    public String generateAccessToken(UUID userId, String email, Set<String> roles,
                                      UUID branchId, UUID shopId, UUID sessionId, String deviceId) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + tokenValidityMs);

        String primaryRole = roles.isEmpty() ? "ROLE_CUSTOMER" : roles.iterator().next();

        return Jwts.builder()
                .header().keyId(activeKid).and()
                .subject(userId.toString())
                .claim("email", email)
                .claim("role", primaryRole) // legacy single-role claim
                .claim("roles", new ArrayList<>(roles)) // multi-role support
                .claim("branchId", branchId != null ? branchId.toString() : null)
                .claim("shopId", shopId != null ? shopId.toString() : null)
                .claim("sessionId", sessionId != null ? sessionId.toString() : null)
                .claim("deviceId", deviceId)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(privateKey, Jwts.SIG.RS256)
                .compact();
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(publicKey)
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Claims getClaims(String token) {
        return Jwts.parser()
                .verifyWith(publicKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Exposes the active public key as a JWKS (JSON Web Key Set) dictionary.
     */
    public Map<String, Object> getJwks() {
        Map<String, Object> jwk = new LinkedHashMap<>();
        jwk.put("kty", "RSA");
        jwk.put("use", "sig");
        jwk.put("alg", "RS256");
        jwk.put("kid", activeKid);

        RSAPublicKey rsaPub = (RSAPublicKey) publicKey;
        jwk.put("n", Base64.getUrlEncoder().withoutPadding().encodeToString(rsaPub.getModulus().toByteArray()));
        jwk.put("e", Base64.getUrlEncoder().withoutPadding().encodeToString(rsaPub.getPublicExponent().toByteArray()));

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("keys", List.of(jwk));
        return response;
    }
}
