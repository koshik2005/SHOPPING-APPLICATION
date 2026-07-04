package com.hyperlocal.gateway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Header;
import io.jsonwebtoken.Jwt;
import io.jsonwebtoken.Jwts;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

@Component
@Order(2)
public class GatewayJwtFilter implements Filter {

    private static final Logger logger = Logger.getLogger(GatewayJwtFilter.class.getName());

    @Value("${service.auth.url:http://localhost:8081}")
    private String authServiceUrl;

    private final Map<String, PublicKey> keyCache = new ConcurrentHashMap<>();
    private final RestTemplate restTemplate = new RestTemplate();

    private static final List<String> PUBLIC_PATH_PREFIXES = List.of(
        "/api/v1/auth/login",
        "/api/v1/auth/google-login",
        "/api/v1/auth/google",
        "/api/v1/auth/register",
        "/api/v1/auth/signup",
        "/api/v1/auth/send-otp",
        "/api/v1/auth/otp/send",
        "/api/v1/auth/verify-otp",
        "/api/v1/auth/otp/verify",
        "/api/v1/auth/verify-password",
        "/api/v1/auth/password/verify",
        "/api/v1/auth/forgot-password",
        "/api/v1/auth/password/forgot",
        "/api/v1/auth/reset-password",
        "/api/v1/auth/password/reset",
        "/api/v1/auth/refresh",
        "/api/v1/auth/token/refresh",
        "/api/v1/auth/jwks.json",
        "/api/v1/config/public",
        "/api/v1/config/app-settings"
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String path = httpRequest.getRequestURI();

        // 1. Bypass auth check for public paths
        if (isPublicPath(path)) {
            chain.doFilter(request, response);
            return;
        }

        // 2. Extract Authorization Header
        String authHeader = httpRequest.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            sendUnauthorized(httpResponse, "Missing or invalid Authorization header");
            return;
        }

        String token = authHeader.substring(7);

        try {
            // 3. Extract kid header without full signature verification first to lookup key
            String kid = getKidFromToken(token);
            if (kid == null) {
                sendUnauthorized(httpResponse, "Token header does not contain kid");
                return;
            }

            // 4. Resolve Public Key from JWKS
            PublicKey publicKey = getPublicKey(kid);
            if (publicKey == null) {
                sendUnauthorized(httpResponse, "Key ID " + kid + " is not trusted");
                return;
            }

            // 5. Parse and Validate Token Claims
            Claims claims = Jwts.parser()
                    .verifyWith(publicKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            // 6. Set claims as forward-headers for downstream services
            MutableHttpServletRequest wrapper = new MutableHttpServletRequest(httpRequest);
            
            String userId = claims.getSubject();
            Object rolesObj = claims.get("roles");
            String rolesStr = "";
            if (rolesObj instanceof List) {
                rolesStr = String.join(",", (List<String>) rolesObj);
            } else if (claims.get("role") != null) {
                rolesStr = (String) claims.get("role");
            }

            String branchId = (String) claims.get("branchId");
            String shopId = (String) claims.get("shopId");
            String sessionId = (String) claims.get("sessionId");

            wrapper.putHeader("X-User-Id", userId);
            wrapper.putHeader("X-User-Roles", rolesStr);
            if (branchId != null) wrapper.putHeader("X-Branch-Id", branchId);
            if (shopId != null) wrapper.putHeader("X-Shop-Id", shopId);
            if (sessionId != null) wrapper.putHeader("X-Session-Id", sessionId);

            chain.doFilter(wrapper, response);

        } catch (Exception e) {
            logger.log(Level.WARNING, "JWT Validation failed: " + e.getMessage(), e);
            sendUnauthorized(httpResponse, "Token validation failed: " + e.getMessage());
        }
    }

    private boolean isPublicPath(String path) {
        return PUBLIC_PATH_PREFIXES.stream().anyMatch(path::startsWith);
    }

    private String getKidFromToken(String token) {
        try {
            int firstDot = token.indexOf('.');
            if (firstDot <= 0) return null;
            String headerJson = new String(Base64.getUrlDecoder().decode(token.substring(0, firstDot)));
            // Simple parsing to extract "kid" without introducing heavy JSON libraries
            int kidIndex = headerJson.indexOf("\"kid\"");
            if (kidIndex < 0) return null;
            int colonIndex = headerJson.indexOf(':', kidIndex);
            int startQuote = headerJson.indexOf('"', colonIndex);
            int endQuote = headerJson.indexOf('"', startQuote + 1);
            if (startQuote > 0 && endQuote > startQuote) {
                return headerJson.substring(startQuote + 1, endQuote);
            }
        } catch (Exception e) {
            logger.log(Level.WARNING, "Failed to parse kid from header: " + e.getMessage());
        }
        return null;
    }

    private PublicKey getPublicKey(String kid) {
        return keyCache.computeIfAbsent(kid, this::fetchPublicKeyFromJwks);
    }

    private PublicKey fetchPublicKeyFromJwks(String kid) {
        try {
            String jwksUrl = authServiceUrl + "/api/v1/auth/jwks.json";
            logger.info("Fetching JWKS from URL: " + jwksUrl);
            Map<String, Object> jwks = restTemplate.getForObject(jwksUrl, Map.class);
            if (jwks == null || !jwks.containsKey("keys")) {
                return null;
            }

            List<Map<String, Object>> keys = (List<Map<String, Object>>) jwks.get("keys");
            for (Map<String, Object> key : keys) {
                if (kid.equals(key.get("kid"))) {
                    String n = (String) key.get("n");
                    String e = (String) key.get("e");

                    byte[] nb = Base64.getUrlDecoder().decode(n);
                    byte[] eb = Base64.getUrlDecoder().decode(e);

                    BigInteger modulus = new BigInteger(1, nb);
                    BigInteger exponent = new BigInteger(1, eb);

                    RSAPublicKeySpec spec = new RSAPublicKeySpec(modulus, exponent);
                    KeyFactory factory = KeyFactory.getInstance("RSA");
                    return factory.generatePublic(spec);
                }
            }
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Failed to fetch key " + kid + " from JWKS", e);
        }
        return null;
    }

    private void sendUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write(String.format(
            "{\"errorCode\":\"UNAUTHORIZED\",\"message\":\"%s\",\"timestamp\":\"%s\"}",
            message, java.time.Instant.now().toString()
        ));
    }

    // Helper request wrapper class to inject downstream headers
    private static class MutableHttpServletRequest extends jakarta.servlet.http.HttpServletRequestWrapper {
        private final Map<String, String> customHeaders = new HashMap<>();

        public MutableHttpServletRequest(HttpServletRequest request) {
            super(request);
        }

        public void putHeader(String name, String value) {
            this.customHeaders.put(name, value);
        }

        @Override
        public String getHeader(String name) {
            String headerValue = customHeaders.get(name);
            if (headerValue != null) {
                return headerValue;
            }
            return ((HttpServletRequest) getRequest()).getHeader(name);
        }

        @Override
        public Enumeration<String> getHeaderNames() {
            Set<String> set = new HashSet<>(customHeaders.keySet());
            Enumeration<String> e = ((HttpServletRequest) getRequest()).getHeaderNames();
            while (e.hasMoreElements()) {
                set.add(e.nextElement());
            }
            return Collections.enumeration(set);
        }
    }
}
