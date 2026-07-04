package com.hyperlocal.common.context;

import java.util.*;

public class AuthContext {
    private static final ThreadLocal<AuthContextData> holder = new ThreadLocal<>();

    public static void set(AuthContextData ctx) {
        holder.set(ctx);
    }

    public static AuthContextData get() {
        return holder.get();
    }

    public static void clear() {
        holder.remove();
    }

    public static UUID requireUserId() {
        return Optional.ofNullable(get())
            .map(AuthContextData::userId)
            .orElseThrow(() -> new RuntimeException("UNAUTHORIZED: No authenticated context"));
    }

    public static UUID requireBranchId() {
        return Optional.ofNullable(get())
            .map(AuthContextData::branchId)
            .orElseThrow(() -> new RuntimeException("FORBIDDEN: No branch scope in token"));
    }

    public static UUID requireShopId() {
        return Optional.ofNullable(get())
            .map(AuthContextData::shopId)
            .orElseThrow(() -> new RuntimeException("FORBIDDEN: No shop scope in token"));
    }

    public record AuthContextData(
        UUID userId,
        Set<String> roles,
        UUID branchId,
        UUID shopId,
        String sessionId,
        String correlationId
    ) {
        public boolean hasRole(String role) {
            return roles.contains(role);
        }

        public boolean isSuperAdmin() {
            return roles.contains("ROLE_SUPER_ADMIN");
        }
    }
}
