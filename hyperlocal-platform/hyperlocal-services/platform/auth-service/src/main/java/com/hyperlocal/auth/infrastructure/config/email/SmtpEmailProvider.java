package com.hyperlocal.auth.infrastructure.config.email;

import com.hyperlocal.common.provider.EmailProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.stereotype.Component;


/**
 * SMTP Email Provider using MailHog (development) or any SMTP server (production).
 * Configuration:
 *   spring.mail.host=localhost (or ${SMTP_HOST})
 *   spring.mail.port=1025      (or ${SMTP_PORT})
 *
 * MailHog web UI available at http://localhost:8025
 */
@Component
@Profile({"dev", "prod"})
public class SmtpEmailProvider implements EmailProvider {

    private static final Logger log = LoggerFactory.getLogger(SmtpEmailProvider.class);

    private final org.springframework.mail.MailSender mailSender;

    @Value("${spring.mail.from:noreply@hyperlocal.app}")
    private String fromAddress;

    public SmtpEmailProvider(org.springframework.mail.MailSender mailSender) {
        this.mailSender = mailSender;
    }


    @Override
    public void sendEmail(String toEmail, String subject, String body) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject(subject);
            message.setText(body);
            mailSender.send(message);
            log.info("[EMAIL] Sent '{}' to {}", subject, toEmail);
        } catch (Exception e) {
            log.error("[EMAIL] Failed to send email to {}: {}", toEmail, e.getMessage());
        }
    }
}
