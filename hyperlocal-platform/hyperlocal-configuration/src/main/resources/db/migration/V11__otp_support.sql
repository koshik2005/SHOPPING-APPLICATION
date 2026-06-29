-- Migration to add OTP support table for email and SMS OTP verifications.
CREATE TABLE one_time_passwords (
    id UUID PRIMARY KEY,
    email_or_phone VARCHAR(150) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    expiry_time TIMESTAMPTZ NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_otps_lookup ON one_time_passwords(email_or_phone, otp_code);
