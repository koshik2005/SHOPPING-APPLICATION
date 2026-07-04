package com.hyperlocal.common.filter;

import com.hyperlocal.common.context.AuthContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

@Component
@Order(5) // Run after MDC filter to populate Context
public class AuthContextFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String userIdStr = request.getHeader("X-User-Id");
        String rolesStr = request.getHeader("X-User-Roles");
        String branchIdStr = request.getHeader("X-Branch-Id");
        String shopIdStr = request.getHeader("X-Shop-Id");
        String sessionId = request.getHeader("X-Session-Id");
        String correlationId = request.getHeader("X-Correlation-ID");

        if (userIdStr != null && !userIdStr.isBlank()) {
            try {
                UUID userId = UUID.fromString(userIdStr.trim());
                Set<String> roles = parseRoles(rolesStr);
                UUID branchId = (branchIdStr != null && !branchIdStr.isBlank()) ? UUID.fromString(branchIdStr.trim()) : null;
                UUID shopId = (shopIdStr != null && !shopIdStr.isBlank()) ? UUID.fromString(shopIdStr.trim()) : null;

                AuthContext.set(new AuthContext.AuthContextData(
                    userId,
                    roles,
                    branchId,
                    shopId,
                    sessionId,
                    correlationId
                ));
            } catch (Exception e) {
                // Log and ignore parsing exceptions
                logger.warn("Failed to parse headers into AuthContext: " + e.getMessage());
            }
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            AuthContext.clear(); // Always clean up thread-local
        }
    }

    private Set<String> parseRoles(String rolesStr) {
        if (rolesStr == null || rolesStr.isBlank()) {
            return Collections.emptySet();
        }
        return Arrays.stream(rolesStr.split(","))
                .map(String::trim)
                .filter(r -> !r.isEmpty())
                .collect(Collectors.toSet());
    }
}
