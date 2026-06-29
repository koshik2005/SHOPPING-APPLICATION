package com.hyperlocal.auth.infrastructure.config;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.hyperlocal.auth.domain.exception.GoogleAuthExceptions.*;
import com.hyperlocal.common.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.Collections;
import java.util.logging.Logger;
import java.util.logging.Level;

@Service
public class GoogleIdTokenVerifierService {
    private static final Logger logger = Logger.getLogger(GoogleIdTokenVerifierService.class.getName());
    private final GoogleIdTokenVerifier verifier;

    public GoogleIdTokenVerifierService(@Value("${google.client.web-id}") String webClientId) {
        if (webClientId == null || webClientId.trim().isEmpty() || webClientId.contains("placeholder")) {
            throw new IllegalArgumentException("CRITICAL CONFIG ERROR: google.client.web-id has not been configured or is set to placeholder!");
        }
        this.verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                .setAudience(Collections.singletonList(webClientId))
                .build();
    }

    public GoogleIdToken.Payload verify(String idTokenString) {
        if (idTokenString == null || idTokenString.trim().isEmpty()) {
            logger.log(Level.WARNING, "Google Verification Failure: Token is null or empty");
            throw new InvalidGoogleTokenException("Token is null or empty");
        }

        try {
            // Official direct signature, issuer, audience, and expiration verification flow
            GoogleIdToken idToken = verifier.verify(idTokenString);
            if (idToken == null) {
                logger.log(Level.WARNING, "Google Verification Failure: Cryptographic signature verification failed");
                throw new InvalidGoogleTokenException("Cryptographic signature verification failed");
            }

            GoogleIdToken.Payload payload = idToken.getPayload();

            // Verify Subject (User ID)
            String subject = payload.getSubject();
            if (subject == null || subject.trim().isEmpty()) {
                logger.log(Level.WARNING, "Google Verification Failure: Subject (sub) is missing");
                throw new InvalidGoogleTokenException("Subject (sub) is missing");
            }

            // Verify Email Verification claim
            Boolean emailVerified = payload.getEmailVerified();
            if (emailVerified == null || !emailVerified) {
                logger.log(Level.WARNING, "Google Verification Failure: Email not verified for subject: {0}", subject);
                throw new EmailNotVerifiedException("Email not verified");
            }

            logger.log(Level.INFO, "Google token successfully verified for email: {0}", payload.getEmail());
            return payload;

        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Google token validation execution error", e);
            throw new InvalidGoogleTokenException("Validation error: " + e.getMessage());
        }
    }
}
