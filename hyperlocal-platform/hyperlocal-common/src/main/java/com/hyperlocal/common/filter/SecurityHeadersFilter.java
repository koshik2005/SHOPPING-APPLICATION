package com.hyperlocal.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Security Headers Filter.
 * Appends hardening HTTP response headers on every response:
 *   - Strict-Transport-Security (HSTS)
 *   - X-Frame-Options
 *   - X-Content-Type-Options
 *   - Referrer-Policy
 *   - Permissions-Policy
 */
@Component
public class SecurityHeadersFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        response.setHeader("Strict-Transport-Security",
                "max-age=31536000; includeSubDomains; preload");
        response.setHeader("X-Frame-Options", "DENY");
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
        response.setHeader("Permissions-Policy",
                "camera=(), microphone=(), geolocation=(self)");
        response.setHeader("X-XSS-Protection", "1; mode=block");

        filterChain.doFilter(request, response);
    }
}
