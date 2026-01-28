#!/bin/bash
set -e

source /app/scripts/common.sh

DB_NAME="${1}"
BACKUP_PATH="${2}"

if [ -z "${DB_NAME}" ]; then
    log_error "Database name not provided"
    exit 1
fi

if [ -z "${BACKUP_PATH}" ]; then
    log_error "Backup path not provided"
    exit 1
fi

log_info "Starting MariaDB backup..."
log_info "Database: ${DB_NAME}"
log_info "Backup path: ${BACKUP_PATH}"

log_info "Backing up database: ${DB_NAME}"
mysqldump --single-transaction \
    -u "${DB_USER}" \
    -p"${DB_PASSWORD}" \
    -h "${DB_HOST}" \
    -P "${DB_PORT}" \
    "${DB_NAME}" 2>/dev/null | gzip > "${BACKUP_PATH}"

BACKUP_SIZE=$(stat -f%z "${BACKUP_PATH}" 2>/dev/null || stat -c%s "${BACKUP_PATH}" 2>/dev/null)
log_info "Backup completed. Size: ${BACKUP_SIZE} bytes"
