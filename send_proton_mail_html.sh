#!/bin/bash

# OpenClaw Proton Mail HTML Sender Script
# Usage: ./send_proton_mail_html.sh "recipient@example.com" "Subject Line" "HTML Body"

# Proton Mail Bridge Configuration (from environment variables)
SMTP_SERVER=${PROTON_MAIL_SMTP_SERVER}
SMTP_PORT=${PROTON_MAIL_SMTP_PORT}
USERNAME=${PROTON_MAIL_USERNAME}
PASSWORD=${PROTON_MAIL_PASSWORD}

# Check if all arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 \"recipient@example.com\" \"Subject Line\" \"HTML Body\""
    exit 1
fi

RECIPIENT="$1"
SUBJECT="$2"
HTML_BODY="$3"

# Check if environment variables are set
if [ -z "$SMTP_SERVER" ] || [ -z "$SMTP_PORT" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Error: Proton Mail Bridge environment variables (PROTON_MAIL_SMTP_SERVER, PROTON_MAIL_SMTP_PORT, PROTON_MAIL_USERNAME, PROTON_MAIL_PASSWORD) are not set."
    exit 1
fi

# Create temporary file for email body
TEMP_FILE=$(mktemp)

# Write email with proper HTML headers
cat > "$TEMP_FILE" << EOF
From: ${USERNAME}
To: ${RECIPIENT}
Subject: ${SUBJECT}
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

${HTML_BODY}
EOF

# Send email using curl with HTML support
curl --url "smtp://${SMTP_SERVER}:${SMTP_PORT}" \
     --ssl-reqd \
     --insecure \
     --mail-from "${USERNAME}" \
     --mail-rcpt "${RECIPIENT}" \
     --user "${USERNAME}:${PASSWORD}" \
     --upload-file "${TEMP_FILE}"

EXIT_CODE=$?

# Clean up
rm -f "$TEMP_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "HTML email successfully sent to ${RECIPIENT} with subject '${SUBJECT}'"
else
    echo "Failed to send HTML email to ${RECIPIENT}"
fi

exit $EXIT_CODE
