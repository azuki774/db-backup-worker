#!/bin/bash
set -e

# PostgreSQL Backup Worker
#
# Required Environment Variables:
#   DB_HOST          - Database host (e.g., "localhost", "db.example.com")
#   DB_PORT          - Database port (e.g., "5432")
#   DB_USER          - Database user (e.g., "postgres")
#   DB_PASSWORD      - Database password
#   DB_NAME          - Database name to backup (e.g., "myapp_db")
#   BACKUP_NAME      - Backup file name without extension (e.g., "mybackup", "daily_backup")
#   BUCKET_NAME      - S3 bucket name (e.g., "my-backups")
#   BUCKET_DIR       - S3 bucket directory/prefix (e.g., "postgres/20250117")
#
# Optional Environment Variables:
#   AWS_REGION       - AWS region (e.g., "us-east-1")
#   AWS_ACCESS_KEY_ID      - AWS access key ID
#   AWS_SECRET_ACCESS_KEY  - AWS secret access key
#   BUCKET_URL       - Custom S3 endpoint URL (e.g., "http://minio:9000" for MinIO)
#   SKIP_S3_UPLOAD   - Skip S3 upload if set to "true" (default: "false")

source /app/scripts/common.sh

log_info "Starting PostgreSQL backup to S3..."

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

if [ "${SKIP_S3_UPLOAD}" = "false" ]; then
    /app/scripts/s3-upload.sh "${BACKUP_PATH}"
else
    log_info "Skipping S3 upload as requested"
    log_info "Backup file available at: ${BACKUP_PATH}"
    log_info "$(ls -lh "${BACKUP_PATH}")"
fi

log_info "Backup completed successfully"
