#!/bin/bash
set -e

source /app/scripts/common.sh

BACKUP_PATH="${1}"

if [ ! -f "${BACKUP_PATH}" ]; then
    log_error "Backup file not found: ${BACKUP_PATH}"
    exit 1
fi

# Build S3 endpoint URL if custom BUCKET_URL is provided
S3_ENDPOINT_ARG=""
if [ -n "${BUCKET_URL}" ]; then
    S3_ENDPOINT_ARG="--endpoint-url ${BUCKET_URL}"
    log_info "Using custom S3 endpoint: ${BUCKET_URL}"
fi

BACKUP_FILE=$(basename "${BACKUP_PATH}")
S3_KEY="${BUCKET_DIR}/${BACKUP_FILE}"

log_info "Starting S3 upload..."
log_info "Source: ${BACKUP_PATH}"
log_info "Destination: s3://${BUCKET_NAME}/${S3_KEY}"

# Verify AWS credentials
verify_aws_credentials

# Get file size
BACKUP_SIZE=$(stat -f%z "${BACKUP_PATH}" 2>/dev/null || stat -c%s "${BACKUP_PATH}" 2>/dev/null)
log_info "File size: ${BACKUP_SIZE} bytes"

# Upload to S3
log_info "Uploading to S3..."

if [ -n "${AWS_REGION}" ]; then
    aws s3 cp "${BACKUP_PATH}" "s3://${BUCKET_NAME}/${S3_KEY}" \
        --region "${AWS_REGION}" \
        ${S3_ENDPOINT_ARG} \
        --only-show-errors
else
    aws s3 cp "${BACKUP_PATH}" "s3://${BUCKET_NAME}/${S3_KEY}" \
        ${S3_ENDPOINT_ARG} \
        --only-show-errors
fi

if [ $? -ne 0 ]; then
    log_error "S3 upload failed"
    exit 1
fi

# Verify upload
log_info "Verifying upload..."

if [ -n "${AWS_REGION}" ]; then
    UPLOADED_SIZE=$(aws s3api head-object \
        --bucket "${BUCKET_NAME}" \
        --key "${S3_KEY}" \
        --region "${AWS_REGION}" \
        ${S3_ENDPOINT_ARG} \
        --query "ContentLength" \
        --output text)
else
    UPLOADED_SIZE=$(aws s3api head-object \
        --bucket "${BUCKET_NAME}" \
        --key "${S3_KEY}" \
        ${S3_ENDPOINT_ARG} \
        --query "ContentLength" \
        --output text)
fi

if [ "${UPLOADED_SIZE}" != "${BACKUP_SIZE}" ]; then
    log_error "Upload verification failed. Size mismatch: local=${BACKUP_SIZE}, uploaded=${UPLOADED_SIZE}"
    exit 1
fi

log_info "Upload verified successfully"

log_info "Cleaning up local backup file..."
rm -f "${BACKUP_PATH}"

log_info "S3 upload completed successfully"
log_info "S3 URI: s3://${BUCKET_NAME}/${S3_KEY}"
