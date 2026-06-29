package com.hyperlocal.common.exception;

import lombok.Getter;

@Getter
public class ResourceNotFoundException extends BusinessException {
    public ResourceNotFoundException(String message, String errorCode) {
        super(message, errorCode);
    }
}
