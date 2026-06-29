package com.hyperlocal.core.domain;

import java.time.Instant;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ApiResponse<T> {
    boolean success;
    String correlationId;
    Instant timestamp;
    T data;
    Object pagination;

    public static <T> ApiResponse<T> ok(T data, String correlationId) {
        return ApiResponse.<T>builder()
                .success(true)
                .correlationId(correlationId)
                .timestamp(Instant.now())
                .data(data)
                .build();
    }
}
