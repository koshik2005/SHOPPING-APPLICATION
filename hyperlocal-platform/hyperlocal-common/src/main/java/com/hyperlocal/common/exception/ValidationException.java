package com.hyperlocal.common.exception;

import lombok.Getter;
import java.util.List;
import com.hyperlocal.core.domain.ApiErrorResponse.ValidationError;

@Getter
public class ValidationException extends RuntimeException {
    private final List<ValidationError> errors;

    public ValidationException(List<ValidationError> errors) {
        super("Validation check failed");
        this.errors = errors;
    }
}
