package com.hyperlocal.auth.domain.exception;

import com.hyperlocal.common.exception.BusinessException;

public class GoogleAuthExceptions {
    public static class InvalidGoogleTokenException extends BusinessException {
        public InvalidGoogleTokenException(String message) {
            super(message, "INVALID_GOOGLE_TOKEN");
        }
    }

    public static class ExpiredGoogleTokenException extends BusinessException {
        public ExpiredGoogleTokenException(String message) {
            super(message, "EXPIRED_GOOGLE_TOKEN");
        }
    }

    public static class InvalidAudienceException extends BusinessException {
        public InvalidAudienceException(String message) {
            super(message, "INVALID_AUDIENCE");
        }
    }

    public static class InvalidIssuerException extends BusinessException {
        public InvalidIssuerException(String message) {
            super(message, "INVALID_ISSUER");
        }
    }

    public static class EmailNotVerifiedException extends BusinessException {
        public EmailNotVerifiedException(String message) {
            super(message, "EMAIL_NOT_VERIFIED");
        }
    }
}
