package com.hyperlocal.core.domain;

import java.time.Instant;
import java.util.List;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ApiErrorResponse {
    boolean success;
    String correlationId;
    Instant timestamp;
    ErrorDetails error;

    @Value
    @Builder
    public static class ErrorDetails {
        String code;
        String message;
        List<ValidationError> details;
    }

    @Value
    @Builder
    public static class ValidationError {
        String field;
        String issue;
    }
}
