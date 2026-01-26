#!/bin/bash
set -e

# MariaDB Backup Worker
#
# Required Environment Variables:
#   DB_HOST          - Database host (e.g., "localhost", "db.example.com")
#   DB_PORT          - Database port (e.g., "3306")
#   DB_USER          - Database user (e.g., "root")
#   DB_PASSWORD      - Database password
#   DB_NAME          - Database name to backup (e.g., "myapp_db")
#   BACKUP_NAME      - Backup file name without extension (e.g., "mybackup", "daily_backup")
#   BUCKET_NAME      - S3 bucket name (e.g., "my-backups")
#   BUCKET_DIR       - S3 bucket directory/prefix (e.g., "mariadb/20250117")
#
# Optional Environment Variables:
#   AWS_REGION       - AWS region (e.g., "us-east-1")
#   AWS_ACCESS_KEY_ID      - AWS access key ID
#   AWS_SECRET_ACCESS_KEY  - AWS secret access key
#   BUCKET_URL       - Custom S3 endpoint URL (e.g., "http://minio:9000" for MinIO)
#   SKIP_S3_UPLOAD   - Skip S3 upload if set to "true" (default: "false")
#   DISCORD_WEBHOOK  - Discord webhook URL for notifications (optional)

source /app/scripts/common.sh

# Track backup success status
BACKUP_SUCCESS=0
S3_URI=""
BACKUP_SIZE=""

# Error handler - called on script failure
error_handler() {
    local exit_code=$?
    if [ ${exit_code} -ne 0 ] && [ ${BACKUP_SUCCESS} -eq 0 ]; then
        log_error "Backup process failed with exit code ${exit_code}"
        send_discord_failure "${DB_NAME}" "MariaDB Backup Notification"
    fi
}

# Success handler - called on script exit
exit_handler() {
    local exit_code=$?
    if [ ${exit_code} -eq 0 ] && [ ${BACKUP_SUCCESS} -eq 1 ]; then
        send_discord_success "${DB_NAME}" "${BACKUP_FILE}" "${S3_URI}" "${BACKUP_SIZE}" "MariaDB Backup Notification"
    fi
}

# Set up trap handlers
trap 'error_handler' ERR
trap 'exit_handler' EXIT

log_info "Starting MariaDB backup to S3..."

if [ "${SKIP_S3_UPLOAD}" = "true" ]; then
    check_required_vars "DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME" "BACKUP_NAME"
else
    check_required_vars "DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME" "BUCKET_NAME" "BUCKET_DIR" "BACKUP_NAME"
fi

BACKUP_FILE="${BACKUP_NAME}.sql.gz"
BACKUP_PATH="/tmp/${BACKUP_FILE}"

log_info "Environment variables loaded"
log_debug "DB_HOST=${DB_HOST}"
log_debug "DB_PORT=${DB_PORT}"
log_debug "DB_NAME=${DB_NAME}"
log_debug "BUCKET_NAME=${BUCKET_NAME}"
log_debug "BUCKET_DIR=${BUCKET_DIR}"

if [ "${SKIP_S3_UPLOAD}" = "true" ]; then
    log_warning "SKIP_S3_UPLOAD is true, skipping S3 upload"
fi

/app/backup.sh "${DB_NAME}" "${BACKUP_PATH}"
/app/verify.sh "${BACKUP_PATH}"

# Get backup file size after verification
BACKUP_SIZE=$(stat -f%z "${BACKUP_PATH}" 2>/dev/null || stat -c%s "${BACKUP_PATH}" 2>/dev/null)

if [ "${SKIP_S3_UPLOAD}" = "false" ]; then
    /app/scripts/s3-upload.sh "${BACKUP_PATH}"
    # Set S3 URI for success notification
    S3_URI="s3://${BUCKET_NAME}/${BUCKET_DIR}/${BACKUP_FILE}"
else
    log_info "Skipping S3 upload as requested"
    log_info "Backup file available at: ${BACKUP_PATH}"
    log_info "$(ls -lh "${BACKUP_PATH}")"
fi

log_info "Backup completed successfully"

# Mark backup as successful
BACKUP_SUCCESS=1
