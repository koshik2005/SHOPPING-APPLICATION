package com.hyperlocal.common.exception;

import com.hyperlocal.common.utils.CorrelationIdUtils;
import com.hyperlocal.core.domain.ApiErrorResponse;
import com.hyperlocal.core.domain.ApiErrorResponse.ErrorDetails;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import java.time.Instant;
import java.util.Collections;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiErrorResponse> handleBusinessException(BusinessException ex) {
        ErrorDetails details = ErrorDetails.builder()
                .code(ex.getErrorCode())
                .message(ex.getMessage())
                .details(Collections.emptyList())
                .build();
                
        ApiErrorResponse response = ApiErrorResponse.builder()
                .success(false)
                .correlationId(CorrelationIdUtils.getCorrelationId())
                .timestamp(Instant.now())
                .error(details)
                .build();
                
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ApiErrorResponse> handleValidationException(ValidationException ex) {
        ErrorDetails details = ErrorDetails.builder()
                .code("VALIDATION_ERROR")
                .message("Input validation check failed")
                .details(ex.getErrors())
                .build();
                
        ApiErrorResponse response = ApiErrorResponse.builder()
                .success(false)
                .correlationId(CorrelationIdUtils.getCorrelationId())
                .timestamp(Instant.now())
                .error(details)
                .build();
                
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGenericException(Exception ex) {
        ErrorDetails details = ErrorDetails.builder()
                .code("INTERNAL_SERVER_ERROR")
                .message(ex.getMessage())
                .details(Collections.emptyList())
                .build();
                
        ApiErrorResponse response = ApiErrorResponse.builder()
                .success(false)
                .correlationId(CorrelationIdUtils.getCorrelationId())
                .timestamp(Instant.now())
                .error(details)
                .build();
                
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}
