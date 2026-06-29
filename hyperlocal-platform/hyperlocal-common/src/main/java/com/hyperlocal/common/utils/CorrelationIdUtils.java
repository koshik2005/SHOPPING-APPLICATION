package com.hyperlocal.common.utils;

import java.util.UUID;

public class CorrelationIdUtils {
    private static final ThreadLocal<String> correlationIdHolder = new ThreadLocal<>();

    public static void setCorrelationId(String id) {
        correlationIdHolder.set(id);
    }

    public static String getCorrelationId() {
        String current = correlationIdHolder.get();
        if (current == null) {
            current = UUID.randomUUID().toString();
            correlationIdHolder.set(current);
        }
        return current;
    }

    public static void clear() {
        correlationIdHolder.remove();
    }
}
